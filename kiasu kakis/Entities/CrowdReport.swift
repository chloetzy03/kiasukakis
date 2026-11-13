import Foundation

// One person's report of how long a line is. For now these stay on the phone; a server would share them.
struct CrowdReport: Codable, Equatable {
    let venueID: String
    let minutes: Int
    let date: Date

    // A report goes stale quickly, because lines change.
    static let lifetime: TimeInterval = 30 * 60

    func isFresh(at now: Date) -> Bool {
        let age = now.timeIntervalSince(date)
        return age >= 0 && age < Self.lifetime
    }
}

// The choices shown when someone reports a line.
enum CrowdReportOption: CaseIterable {
    case none, short, medium, long, veryLong

    var title: String {
        switch self {
        case .none: return "No line"
        case .short: return "About 10 min"
        case .medium: return "About 20 min"
        case .long: return "About 30 min"
        case .veryLong: return "45 min or more"
        }
    }

    var minutes: Int {
        switch self {
        case .none: return 3
        case .short: return 10
        case .medium: return 20
        case .long: return 30
        case .veryLong: return 45
        }
    }
}
