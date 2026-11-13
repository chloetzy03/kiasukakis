import Foundation

enum QueueDataSource: String, Codable {
    case demoSimulation = "Simulated"
    case communityObservation = "Simulated community report"
    case userReport = "Reported by you"
    case officialLive = "Official live data"
}

enum QueueTrend: String, Codable {
    case rising, falling, steady
}

// A reading of a venue's queue. waitMinutes == nil means "no recent data", never zero.
struct QueueSnapshot: Codable, Equatable {
    let venueID: String
    let waitMinutes: Int?
    let source: QueueDataSource
    let timestamp: Date
    var trend: QueueTrend = .steady
}
