import Foundation

final class JoinQueueInteractor: JoinQueueInteractorProtocol {

    let venue: Venue
    private let service: QueueServicing
    private let simulator: QueueSimulating

    init(venue: Venue, service: QueueServicing = QueueService.shared, simulator: QueueSimulating = QueueSimulator.shared) {
        self.venue = venue
        self.service = service
        self.simulator = simulator
    }

    var snapshot: QueueSnapshot { simulator.snapshot(for: venue) }

    func join(partySize: Int) -> Result<QueueTicket, QueueError> {
        service.join(venue: venue, partySize: partySize)
    }
}
