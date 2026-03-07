import Foundation

enum SessionStatus: String, Codable {
    case running
    case paused
    case completed
    case stopped
}

struct TimeEntry: Codable, Identifiable {
    let id: UUID
    var client: String
    var task: String
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    var status: SessionStatus

    var plannedMinutes: Int {
        Int(plannedDuration / 60)
    }

    var actualMinutes: Int {
        Int(actualDuration / 60)
    }

    var formattedPlannedDuration: String {
        let minutes = Int(plannedDuration) / 60
        return "\(minutes)m"
    }

    var formattedActualDuration: String {
        let total = Int(actualDuration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
