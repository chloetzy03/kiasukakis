import UIKit

struct SavedVenueRowViewModel: Equatable {
    let id: String
    let name: String
    let subtitle: String
    let waitColor: UIColor
}

protocol SavedViewProtocol: AnyObject {
    // Empty titles hide the filter bar. Otherwise the first title is "All".
    func showFilters(titles: [String], selectedIndex: Int)
    func show(rows: [SavedVenueRowViewModel])
    func showEmptyState(_ isEmpty: Bool)
}

protocol SavedPresenterProtocol: AnyObject {
    func viewWillAppear()
    func didSelectVenue(id: String)
    func didRemoveVenue(id: String)
    func didSelectCategory(at index: Int)
}

protocol SavedInteractorProtocol: AnyObject {
    func savedListings() -> [VenueListing]
    func remove(venueID: String)
}

protocol SavedRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String)
}
