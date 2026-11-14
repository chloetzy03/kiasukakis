import Foundation

final class JoinQueueInteractor: JoinQueueInteractorProtocol {

    let venue: Venue
    private let service: QueueServicing
    private let simulator: QueueSimulating
    private let configs: VenueConfigProviding

    init(venue: Venue, service: QueueServicing = QueueService.shared, simulator: QueueSimulating = QueueSimulator.shared,
         configs: VenueConfigProviding = BundledVenueConfigs.shared) {
        self.venue = venue
        self.service = service
        self.simulator = simulator
        self.configs = configs
    }

    var config: VenueQueueConfig { configs.config(for: venue) }

    var snapshot: QueueSnapshot { simulator.snapshot(for: venue) }

    var queueLimitMessage: String? {
        guard service.activeTicket(forVenue: venue.id) == nil, service.activeTicketCount >= service.maxActiveTickets else { return nil }
        let count = service.activeTicketCount
        return "You're already in \(count) queues. Leave one in My Queues to join this one."
    }

    func join(partySize: Int) -> Result<QueueTicket, QueueError> {
        service.join(venue: venue, partySize: partySize)
    }
}
