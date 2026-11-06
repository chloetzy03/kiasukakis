import Foundation

protocol SavedVenuesStoring: AnyObject {
    func isSaved(_ venueID: String) -> Bool
    func toggle(_ venueID: String)
}

// Saved venue IDs are written to disk after every change.
final class SavedVenuesStore: SavedVenuesStoring {

    static let shared = SavedVenuesStore()

    private static let filename = "saved_venues.json"
    private let store: LocalStore
    private var ids: Set<String> {
        didSet { store.save(ids, to: Self.filename) }
    }

    init(store: LocalStore = LocalStore()) {
        self.store = store
        self.ids = store.load(Set<String>.self, from: Self.filename) ?? []
    }

    func isSaved(_ venueID: String) -> Bool { ids.contains(venueID) }

    func toggle(_ venueID: String) {
        if ids.contains(venueID) { ids.remove(venueID) } else { ids.insert(venueID) }
    }
}
