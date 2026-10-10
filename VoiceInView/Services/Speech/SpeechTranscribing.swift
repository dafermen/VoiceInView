import Foundation

enum SpeechReadiness: Equatable, Sendable {
    case checking, unsupportedDevice, unsupportedLanguage, missingAssets, downloading, ready
    case authorizationRequired, authorizationDenied, authorizationRestricted, systemModelUnavailable
    case problem(String)

    var description: String {
        switch self {
        case .checking: "Checking English speech model"
        case .unsupportedDevice: "This iPhone does not support the on-device speech engine."
        case .unsupportedLanguage: "English (United States) is unavailable on this device."
        case .missingAssets: "Install the English model before using offline captions."
        case .downloading: "Installing the English speech model"
        case .ready: "On-device English recognition available; verify with an offline test"
        case .authorizationRequired: "Allow speech recognition to check on-device English support."
        case .authorizationDenied: "Speech recognition access is denied. Enable it in Settings > Privacy & Security > Speech Recognition."
        case .authorizationRestricted: "Speech recognition is restricted on this device."
        case .systemModelUnavailable: "On-device English recognition is unavailable. While online, enable English (US) Dictation in iPhone Settings, then refresh and test offline. This app cannot install the system model."
        case .problem(let message): message
        }
    }
}

enum TranscriptionFailure: LocalizedError, Sendable {
    case notReady, format, overflow, failed, interrupted(String), finalizationTimeout
    var errorDescription: String? {
        switch self {
        case .notReady: "Offline transcription is not ready. Check the English model."
        case .format: "The microphone audio could not be converted for recognition."
        case .overflow: "Audio processing could not keep up. Listening stopped to prevent an incomplete transcript."
        case .failed: "Speech analysis failed. Saved final captions remain available."
        case .interrupted(let message): message
        case .finalizationTimeout: "Speech finalization took too long. Current unfinished captions may be incomplete."
        }
    }
}

/// Contrato compartido por los motores reales y los dobles de prueba.
/// start entrega un flujo de revisiones; finish intenta finalizar y cancel puede perder lo provisional.
/// La interfaz no ofrece un fallback de reconocimiento remoto.
@MainActor
protocol SpeechTranscribing: AnyObject {
    func readiness() async -> SpeechReadiness
    func requestAuthorization() async
    func installAssets() async throws
    func start() async throws -> AsyncThrowingStream<TranscriptionUpdate, Error>
    func finish() async throws
    func cancel() async
}

extension SpeechTranscribing {
    func requestAuthorization() async {}
}
