import Foundation

/// Testable boundary for microphone capture. Saving audio is explicitly opt-in.
@MainActor
protocol AudioCapturing: AnyObject {
    var permission: MicrophonePermission { get }
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)? { get set }
    func requestPermission() async -> Bool
    func start() throws -> AsyncStream<Float>
    func stop() throws
}
