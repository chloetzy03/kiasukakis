import Foundation

final class JoinQueueInteractor: JoinQueueInteractorProtocol {

    let venue: Venue
    private let service: QueueServicing

    init(venue: Venue, service: QueueServicing = QueueService.shared) {
        self.venue = venue
        self.service = service
    }

    var snapshot: QueueSnapshot { DemoVenueData.snapshot(for: venue.id) }

    func join(partySize: Int) -> Result<QueueTicket, QueueError> {
        service.join(venue: venue, partySize: partySize)
    }
}
