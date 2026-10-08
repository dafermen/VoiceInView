import AVFoundation
import Foundation

@MainActor
final class AudioCaptureService: SpeechAudioCapturing {
    var audioSink: (@Sendable (CapturedAudio) -> Void)?
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)?
    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var continuation: AsyncStream<Float>.Continuation?
    private var tapInstalled = false
    private var sessionActive = false
    private var observers: [NSObjectProtocol] = []
    private var generation = UUID()

    var permission: MicrophonePermission {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: .undetermined
        case .granted: .granted
        case .denied: .denied
        @unknown default: .unavailable
        }
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws -> AsyncStream<Float> {
        guard permission == .granted else { throw CaptureFailure.permissionDenied }
        try stop()
        let identifier = UUID()
        generation = identifier
        do {
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
            sessionActive = true
        } catch {
            throw CaptureFailure.sessionFailure
        }

        do {
            guard session.isInputAvailable else { throw CaptureFailure.noInput }
            // Prefer the phone microphone over an accidentally selected accessory.
            guard let microphone = session.availableInputs?.first(where: { $0.portType == .builtInMic }) else {
                throw CaptureFailure.noInput
            }
            try session.setPreferredInput(microphone)
            let newEngine = AVAudioEngine()
            engine = newEngine
            let input = newEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0,
                  format.commonFormat == .pcmFormatFloat32 else {
                throw CaptureFailure.invalidFormat
            }
            let stream = AsyncStream<Float>.makeStream(bufferingPolicy: .bufferingNewest(1))
            continuation = stream.continuation
            // Explicit Sendable closure avoids inheriting MainActor on the audio thread.
            // installTap is supported by the selected iOS 26 SDK; its successor requires iOS 27.
            let deliver = stream.continuation
            let sink = audioSink
            let copyFailure: @Sendable () -> Void = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, self.generation == identifier else { return }
                    self.onFailure?(.engineFailure)
                }
            }
            let tap: @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void = { buffer, _ in
                guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return }
                let frames = Int(buffer.frameLength)
                let stride = buffer.stride
                var energy: Float = 0
                for frame in 0..<frames {
                    let sample = channels[0][frame * stride]
                    energy += sample * sample
                }
                let rms = sqrt(energy / Float(frames))
                let decibels = 20 * log10(max(rms, 0.000001))
                deliver.yield(min(max((decibels + 60) / 60, 0), 1))
                if let sink {
                    guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength),
                          let destination = copy.floatChannelData else {
                        copyFailure()
                        return
                    }
                    copy.frameLength = buffer.frameLength
                    for channel in 0..<Int(buffer.format.channelCount) {
                        for frame in 0..<frames {
                            destination[channel][frame * copy.stride] = channels[channel][frame * stride]
                        }
                    }
                    sink(CapturedAudio(buffer: copy))
                }
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format, block: tap)
            tapInstalled = true
            newEngine.prepare()
            try newEngine.start()
            observeChanges(engine: newEngine, identifier: identifier)
            return stream.stream
        } catch {
            let failure = (error as? CaptureFailure) ?? .engineFailure
            do { try stop() } catch { throw CaptureFailure.sessionFailure }
            throw failure
        }
    }

    func stop() throws {
        generation = UUID()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        engine?.stop()
        if tapInstalled { engine?.inputNode.removeTap(onBus: 0) }
        tapInstalled = false
        continuation?.finish()
        continuation = nil
        engine = nil
        if sessionActive {
            do {
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                sessionActive = false
            } catch {
                // Keep the flag so the next stop/start retries deactivation.
                throw CaptureFailure.sessionFailure
            }
        }
    }

    private func observeChanges(engine: AVAudioEngine, identifier: UUID) {
        let center = NotificationCenter.default
        let report: @Sendable (CaptureFailure) -> Void = { [weak self] failure in
            Task { @MainActor [weak self] in
                guard let self, self.generation == identifier else { return }
                self.onFailure?(failure)
            }
        }
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: session, queue: nil
        ) { notification in
            let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if raw == AVAudioSession.InterruptionType.began.rawValue { report(.interruption) }
        })
        let expectedInputs = session.currentRoute.inputs.map { $0.uid }
        let routeChanged: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.generation == identifier else { return }
                let actualInputs = self.session.currentRoute.inputs.map { $0.uid }
                if actualInputs != expectedInputs || !self.session.isInputAvailable {
                    self.onFailure?(.routeChanged)
                }
            }
        }
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: session, queue: nil
        ) { notification in
            let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            // Category/override changes initiated by setup are not input loss.
            switch raw {
            case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue,
                 AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue,
                 AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue,
                 AVAudioSession.RouteChangeReason.routeConfigurationChange.rawValue:
                routeChanged()
            default: break
            }
        })
        observers.append(center.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == identifier, self.engine?.isRunning == false else { return }
                self.onFailure?(.configurationChanged)
            }
        })
        for name in [AVAudioSession.mediaServicesWereLostNotification, AVAudioSession.mediaServicesWereResetNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: nil) { _ in
                report(.mediaServicesChanged)
            })
        }
    }
}
