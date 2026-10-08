import Foundation

enum SessionClock {
    static func seconds(_ duration: Duration) -> TimeInterval {
        let parts = duration.components
        return max(0, Double(parts.seconds) + Double(parts.attoseconds) / 1_000_000_000_000_000_000)
    }

    static func format(_ duration: TimeInterval) -> String {
        let seconds = Int(min(Double(Int.max / 2), max(0, duration.isFinite ? duration : 0)))
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
