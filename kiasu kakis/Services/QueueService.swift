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
    @discardableResult func progressTickets(now: Date, interval: TimeInterval) -> Bool
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

    private let simulator: QueueSimulating
    private let clock: () -> Date
    private var tickObserver: NSObjectProtocol?

    init(store: LocalStore = LocalStore(),
         simulator: QueueSimulating = QueueSimulator.shared,
         clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.simulator = simulator
        self.clock = clock
        self.tickets = store.load([QueueTicket].self, from: Self.filename) ?? []
        // Every simulator tick, move the user's tickets forward and tell the screens if anything changed.
        tickObserver = NotificationCenter.default.addObserver(forName: .queueSimulatorDidTick, object: simulator as AnyObject,
                                                              queue: .main) { [weak self] note in
            guard let self else { return }
            let ticketsMoved = progressTickets(now: self.clock(), interval: simulator.speed.groupInterval)
            let waitsChanged = note.userInfo?["waitsChanged"] as? Bool ?? false
            if ticketsMoved || waitsChanged { NotificationCenter.default.post(name: .queueDataDidChange, object: nil) }
        }
    }

    deinit {
        if let tickObserver { NotificationCenter.default.removeObserver(tickObserver) }
    }

    func ticket(id: UUID) -> QueueTicket? { tickets.first { $0.id == id } }

    func activeTicket(forVenue venueID: String) -> QueueTicket? {
        tickets.first { $0.venueID == venueID && $0.status.isActive }
    }

    func join(venue: Venue, partySize: Int) -> Result<QueueTicket, QueueError> {
        guard venue.queueSupport == .demoSupported else { return .failure(.notAvailable) }
        if let existing = activeTicket(forVenue: venue.id) { return .failure(.alreadyJoined(existing)) }

        let nowServing = Int.random(in: 20..<60)
        let ahead = Self.groupsAhead(for: simulator.snapshot(for: venue.id))
        let ticket = QueueTicket(id: UUID(),
                                 venueID: venue.id,
                                 venueName: venue.name,
                                 partySize: partySize,
                                 ticketNumber: nowServing + ahead,
                                 nowServing: nowServing,
                                 status: .waiting,
                                 createdAt: clock(),
                                 lastProgressAt: clock())
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
        tickets[index].lastProgressAt = clock()
        tickets[index].status = Self.status(for: tickets[index])
    }

    // Moves waiting tickets forward by however many groups have been served since they last moved.
    // Also catches up after the app was closed. A ticket stops moving once it is called.
    @discardableResult
    func progressTickets(now: Date, interval: TimeInterval) -> Bool {
        var updated = tickets
        var changed = false
        for index in updated.indices where updated[index].status == .waiting || updated[index].status == .almostYourTurn {
            guard let last = updated[index].lastProgressAt else {
                updated[index].lastProgressAt = now
                changed = true
                continue
            }
            let steps = Int(now.timeIntervalSince(last) / interval)
            guard steps > 0 else { continue }
            // Never go past the ticket's own number.
            updated[index].nowServing += min(steps, updated[index].position)
            updated[index].lastProgressAt = last.addingTimeInterval(Double(steps) * interval)
            updated[index].status = Self.status(for: updated[index])
            changed = true
        }
        if changed { tickets = updated }
        return changed
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
