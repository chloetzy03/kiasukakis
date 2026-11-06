import Foundation

final class SavedInteractor: SavedInteractorProtocol {

    private let store: SavedVenuesStoring

    init(store: SavedVenuesStoring = SavedVenuesStore.shared) {
        self.store = store
    }

    func savedListings() -> [VenueListing] {
        let saved = store.savedIDs
        return DemoVenueData.venues
            .filter { saved.contains($0.id) }
            .sorted { $0.name < $1.name }
            .map { VenueListing(venue: $0, snapshot: DemoVenueData.snapshot(for: $0.id)) }
    }

    func remove(venueID: String) {
        if store.isSaved(venueID) { store.toggle(venueID) }
    }
}
