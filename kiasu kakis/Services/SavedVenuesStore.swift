import Foundation

protocol SavedVenuesStoring: AnyObject {
    func isSaved(_ venueID: String) -> Bool
    func toggle(_ venueID: String)
}

// In-memory for now. Milestone 5 makes this survive app relaunches.
final class SavedVenuesStore: SavedVenuesStoring {

    static let shared = SavedVenuesStore()
    private var ids: Set<String> = []

    func isSaved(_ venueID: String) -> Bool { ids.contains(venueID) }

    func toggle(_ venueID: String) {
        if ids.contains(venueID) { ids.remove(venueID) } else { ids.insert(venueID) }
    }
}
