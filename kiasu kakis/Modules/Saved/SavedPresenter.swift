import UIKit

final class SavedPresenter: SavedPresenterProtocol {

    weak var view: SavedViewProtocol?
    private let interactor: SavedInteractorProtocol
    private var queueObserver: QueueChangeObserver?
    private let router: SavedRouterProtocol
    private var category: VenueCategory?
    // The categories that have at least one saved place, in the same order as the filter chips.
    private var filterCategories: [VenueCategory] = []

    init(interactor: SavedInteractorProtocol, router: SavedRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewWillAppear() {
        if queueObserver == nil { queueObserver = QueueChangeObserver { [weak self] in self?.refresh() } }
        refresh()
    }

    func didSelectVenue(id: String) { router.showVenueDetails(venueID: id) }

    func didRemoveVenue(id: String) {
        interactor.remove(venueID: id)
        refresh()
    }

    func didSelectCategory(at index: Int) {
        category = index == 0 ? nil : filterCategories[safe: index - 1]
        refresh()
    }

    private func refresh() {
        let all = interactor.savedListings()
        // Only categories you have saved get a chip, and the bar only appears when there is something to choose between.
        filterCategories = VenueCategory.allCases.filter { candidate in all.contains { $0.venue.category == candidate } }
        if let category, !filterCategories.contains(category) { self.category = nil }

        let shown = category.map { selected in all.filter { $0.venue.category == selected } } ?? all
        let selectedIndex = category.flatMap { filterCategories.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        view?.showFilters(titles: filterCategories.count > 1 ? ["All"] + filterCategories.map(\.rawValue) : [],
                          selectedIndex: selectedIndex)
        view?.show(rows: shown.map { Self.makeRow($0) })
        view?.showEmptyState(all.isEmpty)
    }

    private static func makeRow(_ listing: VenueListing) -> SavedVenueRowViewModel {
        let wait = ExplorePresenter.waitText(for: listing.snapshot)
        let queue: String
        switch listing.venue.queueSupport {
        case .demoSupported: queue = "Queue available"
        case .closed: queue = "Queue closed"
        case .unsupported: queue = "No remote queue"
        }
        return SavedVenueRowViewModel(id: listing.venue.id,
                                      name: listing.venue.name,
                                      subtitle: "\(listing.venue.category.rawValue) · \(wait) · \(queue)",
                                      waitColor: Theme.waitColor(forMinutes: listing.snapshot.waitMinutes))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
