import Foundation

enum SessionClock {
    static func format(_ duration: TimeInterval) -> String {
        let seconds = Int(max(0, duration.isFinite ? duration : 0))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

extension CaptionState {
    var title: String {
        switch self {
        case .idle: "Ready to start"
        case .preparing: "Preparing microphone and speech"
        case .listening: "LIVE · Listening"
        case .stopping: "Finalizing captions"
        case .paused: "Paused"
        case .ended: "Session ended"
        case .problem: "Listening stopped"
        }
    }
}
