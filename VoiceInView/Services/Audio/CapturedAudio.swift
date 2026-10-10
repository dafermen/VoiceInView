import AVFoundation

/// Owns a copy of a tap buffer. Consumers must only read it; ownership never returns to the tap.
struct CapturedAudio: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    var sessionStart: Double? = nil
}

@MainActor
protocol SpeechAudioCapturing: AudioCapturing {
    var audioSink: (@Sendable (CapturedAudio) -> Void)? { get set }
}
