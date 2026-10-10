import Foundation

/// Testable boundary for microphone capture. Saving audio is explicitly opt-in.
@MainActor
protocol AudioCapturing: AnyObject {
    var onLevel: (@MainActor @Sendable (Float) -> Void)? { get set }
    var permission: MicrophonePermission { get }
    var onFailure: (@MainActor @Sendable (CaptureFailure) -> Void)? { get set }
    func requestPermission() async -> Bool
    func start() throws -> AsyncStream<Float>
    func stop() throws
}

// Non-metered test doubles and readiness tools can omit the optional display callback.
extension AudioCapturing {
    var onLevel: (@MainActor @Sendable (Float) -> Void)? {
        get { nil }
        set { }
    }
}
