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
    // When the queue last moved on its own. nil for tickets saved before the live queue existed.
    var lastProgressAt: Date?
    // How long the user's trip to the venue takes, once their location is known. Used for the "time to leave" alert.
    var travelMinutes: Int?
    // Set when the user taps "I'm here" or is found near the venue.
    var arrivedAt: Date?
    // When the ticket was called. The user has a short grace period from here to arrive.
    var calledAt: Date?

    // People ahead of the user in the queue.
    var position: Int { max(ticketNumber - nowServing, 0) }

    // When a called ticket is given up on. nil until it has been called.
    func deadline(grace: TimeInterval) -> Date? {
        calledAt.map { $0.addingTimeInterval(grace) }
    }
}
