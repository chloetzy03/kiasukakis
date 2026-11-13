import Foundation

enum QueueError: Error {
    case notAvailable
    case alreadyJoined(QueueTicket)
    // You can only be in a few queues at once, so nobody can hold a place in every queue.
    case tooManyActive(limit: Int)
}

protocol QueueServicing: AnyObject {
    var tickets: [QueueTicket] { get }
    var activeTicketCount: Int { get }
    var maxActiveTickets: Int { get }
    func ticket(id: UUID) -> QueueTicket?
    func activeTicket(forVenue venueID: String) -> QueueTicket?
    func join(venue: Venue, partySize: Int) -> Result<QueueTicket, QueueError>
    func advance(ticketID: UUID)
    func cancel(ticketID: UUID)
    // Removes tickets from the history. Active tickets are never removed by id.
    func deleteTicket(id: UUID)
    func deleteTickets(where shouldDelete: (QueueTicket) -> Bool)
    func setTravelMinutes(_ minutes: Int, forTicket id: UUID)
    func checkIn(ticketID: UUID)
    // Gives a called ticket more time, once.
    func requestMoreTime(ticketID: UUID)
    // Gives up on called tickets whose grace period has run out. Returns true if any changed.
    @discardableResult func expireLateTickets(now: Date, grace: TimeInterval) -> Bool
    @discardableResult func progressTickets(now: Date, interval: TimeInterval) -> Bool
}

// Simulated queue. In a real app the venue's system would control queue progress, not the customer.
// Tickets are saved to disk after every change, so they survive relaunching the app.
final class QueueService: QueueServicing {

    static let shared = QueueService()
    static let minutesPerGroup = 5
    // A real restaurant would not hold places for someone who is queueing everywhere else, so the number is limited.
    static let maxActiveTickets = 2

    // Groups ahead of a new ticket, derived from the venue's demo wait time.
    static func groupsAhead(for snapshot: QueueSnapshot) -> Int {
        max(2, (snapshot.waitMinutes ?? 10) / minutesPerGroup)
    }

    private static let filename = "tickets.json"
    private let store: LocalStore

    private(set) var tickets: [QueueTicket] {
        didSet {
            store.save(tickets, to: Self.filename)
            syncAlerts()
        }
    }

    private let simulator: QueueSimulating
    private let notifier: TicketNotifying
    private let clock: () -> Date
    private var tickObserver: NSObjectProtocol?

    init(store: LocalStore = LocalStore(),
         simulator: QueueSimulating = QueueSimulator.shared,
         notifier: TicketNotifying = LocalTicketNotifier.shared,
         clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.simulator = simulator
        self.notifier = notifier
        self.clock = clock
        self.tickets = store.load([QueueTicket].self, from: Self.filename) ?? []
        // Every simulator tick, move the user's tickets forward and tell the screens if anything changed.
        tickObserver = NotificationCenter.default.addObserver(forName: .queueSimulatorDidTick, object: simulator as AnyObject,
                                                              queue: .main) { [weak self] note in
            guard let self else { return }
            let ticketsMoved = progressTickets(now: self.clock(), interval: simulator.speed.groupInterval)
            let expired = expireLateTickets(now: self.clock(), grace: simulator.speed.graceSeconds)
            // A called ticket has a countdown on screen, so screens refresh every tick while one exists.
            let counting = tickets.contains { $0.status == .called }
            let waitsChanged = note.userInfo?["waitsChanged"] as? Bool ?? false
            // The demo speed can change between ticks, which changes when alerts should fire.
            self.syncAlerts()
            if ticketsMoved || waitsChanged || expired || counting { NotificationCenter.default.post(name: .queueDataDidChange, object: nil) }
        }
    }

    private func syncAlerts() {
        notifier.sync(tickets: tickets, interval: simulator.speed.groupInterval, grace: simulator.speed.graceSeconds, now: clock())
    }

    deinit {
        if let tickObserver { NotificationCenter.default.removeObserver(tickObserver) }
    }

    var activeTicketCount: Int { tickets.filter { $0.status.isActive }.count }

    var maxActiveTickets: Int { Self.maxActiveTickets }

    func ticket(id: UUID) -> QueueTicket? { tickets.first { $0.id == id } }

    func activeTicket(forVenue venueID: String) -> QueueTicket? {
        tickets.first { $0.venueID == venueID && $0.status.isActive }
    }

    func join(venue: Venue, partySize: Int) -> Result<QueueTicket, QueueError> {
        guard venue.queueSupport == .native else { return .failure(.notAvailable) }
        if let existing = activeTicket(forVenue: venue.id) { return .failure(.alreadyJoined(existing)) }
        guard activeTicketCount < maxActiveTickets else { return .failure(.tooManyActive(limit: maxActiveTickets)) }

        let nowServing = Int.random(in: 20..<60)
        let ahead = Self.groupsAhead(for: simulator.snapshot(for: venue))
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
        // Ask when the user first joins, so the reason for the question is clear.
        notifier.requestPermissionIfNeeded()
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
        if tickets[index].status == .called { tickets[index].calledAt = clock() }
        completeIfArrived(index)
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
            let positionBefore = updated[index].position
            // Never go past the ticket's own number.
            updated[index].nowServing += min(steps, updated[index].position)
            updated[index].lastProgressAt = last.addingTimeInterval(Double(steps) * interval)
            updated[index].status = Self.status(for: updated[index])
            // Count the grace period from when the ticket was actually called, even if the app was closed then.
            if updated[index].status == .called {
                updated[index].calledAt = last.addingTimeInterval(Double(positionBefore) * interval)
                if updated[index].arrivedAt != nil { updated[index].status = .completed }
            }
            changed = true
        }
        if changed { tickets = updated }
        return changed
    }

    func deleteTicket(id: UUID) {
        deleteTickets { $0.id == id && !$0.status.isActive }
    }

    func deleteTickets(where shouldDelete: (QueueTicket) -> Bool) {
        let remaining = tickets.filter { !shouldDelete($0) }
        if remaining.count != tickets.count { tickets = remaining }
    }

    func setTravelMinutes(_ minutes: Int, forTicket id: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == id }), tickets[index].status.isActive,
              tickets[index].travelMinutes != minutes else { return }
        tickets[index].travelMinutes = minutes
    }

    func checkIn(ticketID: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }), tickets[index].status.isActive,
              tickets[index].arrivedAt == nil else { return }
        tickets[index].arrivedAt = clock()
        // Arriving after being called means the user is being seated, so the ticket is done.
        if tickets[index].status == .called { tickets[index].status = .completed }
    }

    func requestMoreTime(ticketID: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }), tickets[index].canRequestMoreTime else { return }
        tickets[index].lateExtensions = tickets[index].extensionCount + 1
    }

    @discardableResult
    func expireLateTickets(now: Date, grace: TimeInterval) -> Bool {
        var updated = tickets
        var changed = false
        for index in updated.indices where updated[index].status == .called {
            // Tickets called before grace periods existed get one starting now.
            if updated[index].calledAt == nil { updated[index].calledAt = now; changed = true; continue }
            guard let deadline = updated[index].deadline(grace: grace), now >= deadline else { continue }
            updated[index].status = .expired
            changed = true
        }
        if changed { tickets = updated }
        return changed
    }

    func cancel(ticketID: UUID) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }), tickets[index].status.isActive else { return }
        tickets[index].status = .cancelled
    }

    // A ticket that is called while its owner is already at the venue needs no countdown.
    private func completeIfArrived(_ index: Int) {
        if tickets[index].status == .called, tickets[index].arrivedAt != nil { tickets[index].status = .completed }
    }

    private static func status(for ticket: QueueTicket) -> QueueStatus {
        switch ticket.ticketNumber - ticket.nowServing {
        case ..<1: return .called
        case 1: return .almostYourTurn
        default: return .waiting
        }
    }
}
