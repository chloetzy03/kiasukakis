import Foundation

// Stretch goal: a locally stored observation, not a public live update.
struct QueueReport: Codable, Identifiable, Equatable {
    let id: UUID
    let venueID: String
    let observedWaitMinutes: Int?
    let note: String
    let createdAt: Date
}
