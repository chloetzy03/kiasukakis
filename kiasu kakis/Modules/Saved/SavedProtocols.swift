import UIKit

struct SavedVenueRowViewModel {
    let id: String
    let name: String
    let subtitle: String
    let waitColor: UIColor
}

protocol SavedViewProtocol: AnyObject {
    func show(rows: [SavedVenueRowViewModel])
    func showEmptyState(_ isEmpty: Bool)
}

protocol SavedPresenterProtocol: AnyObject {
    func viewWillAppear()
    func didSelectVenue(id: String)
    func didRemoveVenue(id: String)
}

protocol SavedInteractorProtocol: AnyObject {
    func savedListings() -> [VenueListing]
    func remove(venueID: String)
}

protocol SavedRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String)
}
