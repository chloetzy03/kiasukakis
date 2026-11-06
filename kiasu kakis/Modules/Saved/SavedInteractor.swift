import Foundation

final class SavedInteractor: SavedInteractorProtocol {

    private let store: SavedVenuesStoring
    private let repository: VenueProviding

    init(store: SavedVenuesStoring = SavedVenuesStore.shared,
         repository: VenueProviding = VenueRepository.shared) {
        self.store = store
        self.repository = repository
    }

    func savedListings() -> [VenueListing] {
        let saved = store.savedIDs
        return repository.venues
            .filter { saved.contains($0.id) }
            .sorted { $0.name < $1.name }
            .map { VenueListing(venue: $0, snapshot: DemoVenueData.snapshot(for: $0.id)) }
    }

    func remove(venueID: String) {
        if store.isSaved(venueID) { store.toggle(venueID) }
    }
}
