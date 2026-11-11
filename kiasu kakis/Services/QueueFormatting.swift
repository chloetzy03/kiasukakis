import Foundation

// Wording for live queue data, shared by every screen so they all say the same thing.
enum QueueFormatting {

    static func arrow(for trend: QueueTrend) -> String {
        switch trend {
        case .rising: return "▲"
        case .falling: return "▼"
        case .steady: return "→"
        }
    }

    static func trendWord(for trend: QueueTrend) -> String {
        switch trend {
        case .rising: return "Rising"
        case .falling: return "Falling"
        case .steady: return "Steady"
        }
    }

    // "15 min ▲" when moving, "15 min" when steady, "No recent reports" when there is no data (never "0 min").
    static func waitText(_ snapshot: QueueSnapshot) -> String {
        guard let minutes = snapshot.waitMinutes else { return "No recent reports" }
        return snapshot.trend == .steady ? "\(minutes) min" : "\(minutes) min \(arrow(for: snapshot.trend))"
    }

    // "just now", "20 seconds ago", "2 minutes ago".
    static func ago(_ date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(Int(seconds)) seconds ago" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func updatedText(_ snapshot: QueueSnapshot, now: Date = Date()) -> String {
        "Updated \(ago(snapshot.timestamp, now: now)) · \(arrow(for: snapshot.trend)) \(trendWord(for: snapshot.trend))"
    }
}

// Runs a closure on the main thread whenever a wait time or ticket changes.
// A screen keeps one of these alive for as long as it wants updates.
final class QueueChangeObserver {
    private var token: NSObjectProtocol?

    init(_ handler: @escaping () -> Void) {
        token = NotificationCenter.default.addObserver(forName: .queueDataDidChange, object: nil, queue: .main) { _ in handler() }
    }

    deinit {
        if let token { NotificationCenter.default.removeObserver(token) }
    }
}
