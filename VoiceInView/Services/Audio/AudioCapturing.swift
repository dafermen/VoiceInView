import Foundation

/// Testable boundary for transient microphone capture; audio is never persisted.
@MainActor
protocol AudioCapturing: AnyObject {
    var permission: MicrophonePermission { get }
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)? { get set }
    func requestPermission() async -> Bool
    func start() throws -> AsyncStream<Float>
    func stop() throws
}
