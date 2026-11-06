import Foundation

final class VenueDetailsInteractor: VenueDetailsInteractorProtocol {

    let venue: Venue
    private let store: SavedVenuesStoring
    private let queueService: QueueServicing

    init(venue: Venue,
         store: SavedVenuesStoring = SavedVenuesStore.shared,
         queueService: QueueServicing = QueueService.shared) {
        self.venue = venue
        self.store = store
        self.queueService = queueService
    }

    var activeTicket: QueueTicket? { queueService.activeTicket(forVenue: venue.id) }

    var snapshot: QueueSnapshot { DemoVenueData.snapshot(for: venue.id) }
    var isSaved: Bool { store.isSaved(venue.id) }
    func toggleSaved() { store.toggle(venue.id) }
}
