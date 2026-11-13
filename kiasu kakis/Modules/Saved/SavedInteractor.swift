import Foundation

final class SavedInteractor: SavedInteractorProtocol {

    private let store: SavedVenuesStoring
    private let repository: VenueProviding
    private let simulator: QueueSimulating

    init(store: SavedVenuesStoring = SavedVenuesStore.shared,
         repository: VenueProviding = VenueRepository.shared,
         simulator: QueueSimulating = QueueSimulator.shared) {
        self.store = store
        self.repository = repository
        self.simulator = simulator
    }

    func savedListings() -> [VenueListing] {
        let saved = store.savedIDs
        return repository.venues
            .filter { saved.contains($0.id) }
            .sorted { $0.name < $1.name }
            .map { VenueListing(venue: $0, snapshot: simulator.snapshot(for: $0)) }
    }

    func remove(venueID: String) {
        if store.isSaved(venueID) { store.toggle(venueID) }
    }
}
