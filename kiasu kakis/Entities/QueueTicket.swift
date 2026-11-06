import Foundation

enum QueueStatus: String, Codable {
    case waiting = "Waiting"
    case almostYourTurn = "Almost your turn"
    case called = "Called"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case expired = "Expired"

    var isActive: Bool {
        switch self {
        case .waiting, .almostYourTurn, .called: return true
        case .completed, .cancelled, .expired: return false
        }
    }
}

struct QueueTicket: Codable, Identifiable, Equatable {
    let id: UUID
    let venueID: String
    let venueName: String
    let partySize: Int
    let ticketNumber: Int
    var nowServing: Int
    var status: QueueStatus
    let createdAt: Date

    // People ahead of the user in the queue.
    var position: Int { max(ticketNumber - nowServing, 0) }
}
