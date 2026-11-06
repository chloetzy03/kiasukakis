import Foundation

final class VenueDetailsInteractor: VenueDetailsInteractorProtocol {

    let venue: Venue
    private let store: SavedVenuesStoring

    init(venue: Venue, store: SavedVenuesStoring = SavedVenuesStore.shared) {
        self.venue = venue
        self.store = store
    }

    var snapshot: QueueSnapshot { DemoVenueData.snapshot(for: venue.id) }
    var isSaved: Bool { store.isSaved(venue.id) }
    func toggleSaved() { store.toggle(venue.id) }
}
