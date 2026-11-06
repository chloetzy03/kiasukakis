import UIKit

final class SavedPresenter: SavedPresenterProtocol {

    weak var view: SavedViewProtocol?
    private let interactor: SavedInteractorProtocol
    private let router: SavedRouterProtocol

    init(interactor: SavedInteractorProtocol, router: SavedRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewWillAppear() { refresh() }

    func didSelectVenue(id: String) { router.showVenueDetails(venueID: id) }

    func didRemoveVenue(id: String) {
        interactor.remove(venueID: id)
        refresh()
    }

    private func refresh() {
        let listings = interactor.savedListings()
        view?.show(rows: listings.map { Self.makeRow($0) })
        view?.showEmptyState(listings.isEmpty)
    }

    private static func makeRow(_ listing: VenueListing) -> SavedVenueRowViewModel {
        let wait = ExplorePresenter.waitText(for: listing.snapshot)
        let queue: String
        switch listing.venue.queueSupport {
        case .demoSupported: queue = "Demo queue available"
        case .closed: queue = "Queue closed"
        case .unsupported: queue = "No remote queue"
        }
        return SavedVenueRowViewModel(id: listing.venue.id,
                                      name: listing.venue.name,
                                      subtitle: "\(listing.venue.category.rawValue) · \(wait) · \(queue)",
                                      waitColor: Theme.waitColor(forMinutes: listing.snapshot.waitMinutes))
    }
}
