import Foundation

enum QueueError: Error {
    case notAvailable
    case alreadyJoined(QueueTicket)
}

protocol QueueServicing: AnyObject {
    var tickets: [QueueTicket] { get }
    func ticket(id: UUID) -> QueueTicket?
    func activeTicket(forVenue venueID: String) -> QueueTicket?
    func join(venue: Venue, partySize: Int) -> Result<QueueTicket, QueueError>
    func advance(ticketID: UUID)
    func cancel(ticketID: UUID)
}

// Simulated queue. In a real app the venue's system would control queue progress, not the customer.
// Tickets are saved to disk after every change, so they survive relaunching the app.
final class QueueService: QueueServicing {

    static let shared = QueueService()
    static let minutesPerGroup = 5

    // Groups ahead of a new ticket, derived from the venue's demo wait time.
    static func groupsAhead(for snapshot: QueueSnapshot) -> Int {
        max(2, (snapshot.waitMinutes ?? 10) / minutesPerGroup)
    }

    private static let filename = "tickets.json"
    private let store: LocalStore

    private(set) var tickets: [QueueTicket] {
        didSet { store.save(tickets, to: Self.filename) }
    }

    init(store: LocalStore = LocalStore()) {
        self.store = store
        self.tickets = store.load([QueueTicket].self, from: Self.filename) ?? []
    }

    func ticket(id: UUID) -> QueueTicket? { tickets.first { $0.id == id } }

    func activeTicket(forVenue venueID: String) -> QueueTicket? {
        tickets.first { $0.venueID == venueID && $0.status.isActive }
    }

    func join(venue: Venue, partySize: Int) -> Result<QueueTicket, QueueError> {
        guard venue.queueSupport == .demoSupported else { return .failure(.notAvailable) }
        if let existing = activeTicket(forVenue: venue.id) { return .failure(.alreadyJoined(existing)) }

        let nowServing = Int.random(in: 20..<60)
        let ahead = Self.groupsAhead(for: DemoVenueData.snapshot(for: venue.id))
        let ticket = QueueTicket(id: UUID(),
                                 venueID: venue.id,
                                 venueName: venue.name,
                                 partySize: partySize,
                                 ticketNumber: nowServing + ahead,
                                 nowServing: nowServing,
                                 status: .waiting,
                                 createdAt: Date())
        tickets.insert(ticket, at: 0)
        return .success(ticket)
    }

    // Demo control: moves the queue forward by one, or completes a called ticket.
    func advance(ticketID: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }), tickets[index].status.isActive else { return }
        if tickets[index].status == .called {
            tickets[index].status = .completed
            return
        }
        tickets[index].nowServing += 1
        tickets[index].status = Self.status(for: tickets[index])
    }

    func cancel(ticketID: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }), tickets[index].status.isActive else { return }
        tickets[index].status = .cancelled
    }

    private static func status(for ticket: QueueTicket) -> QueueStatus {
        switch ticket.ticketNumber - ticket.nowServing {
        case ..<1: return .called
        case 1: return .almostYourTurn
        default: return .waiting
        }
    }
}
