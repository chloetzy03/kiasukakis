import UIKit

// Glue: reacts to user actions, asks the interactor for data, formats it for the view.
final class ExplorePresenter: ExplorePresenterProtocol {

    weak var view: ExploreViewProtocol?
    private let interactor: ExploreInteractorProtocol
    private let router: ExploreRouterProtocol
    private let networkMonitor: NetworkMonitoring

    private var query = ""
    private var category: VenueCategory?
    private var selectedID: String?
    private let categories = VenueCategory.allCases

    init(interactor: ExploreInteractorProtocol,
         router: ExploreRouterProtocol,
         networkMonitor: NetworkMonitoring = NetworkMonitor()) {
        self.interactor = interactor
        self.router = router
        self.networkMonitor = networkMonitor
    }

    func viewDidLoad() {
        view?.showCategories(["All"] + categories.map(\.rawValue), selectedIndex: 0)
        refresh()
        networkMonitor.onStatusChange = { [weak self] isOnline in
            self?.view?.showOfflineBanner(!isOnline)
        }
        networkMonitor.start()
    }

    func didChangeSearch(_ text: String) {
        query = text
        refresh()
    }

    func didSelectCategory(at index: Int) {
        category = index == 0 ? nil : categories[index - 1]
        refresh()
    }

    func didSelectVenue(id: String) {
        selectedID = id
        view?.showPreview(interactor.listing(id: id).map { Self.makePreview($0) })
    }

    func didDeselectVenue() {
        selectedID = nil
        view?.showPreview(nil)
    }

    func didTapPreview() {
        guard let id = selectedID, let listing = interactor.listing(id: id) else { return }
        router.showVenueDetails(venueID: id, venueName: listing.venue.name)
    }

    private func refresh() {
        let listings = interactor.listings(matching: query, category: category)
        if let selectedID, !listings.contains(where: { $0.venue.id == selectedID }) {
            self.selectedID = nil
            view?.showPreview(nil)
        }
        view?.showPins(listings.map { Self.makePin($0) }, selectedID: selectedID)
        view?.showEmptyState(listings.isEmpty ? "No venues match your search." : nil)
    }

    // MARK: - Formatting

    static func waitText(for snapshot: QueueSnapshot) -> String {
        guard let minutes = snapshot.waitMinutes else { return "No recent reports" }
        return "\(minutes) min"
    }

    private static func makePin(_ listing: VenueListing) -> VenuePinViewModel {
        let minutes = listing.snapshot.waitMinutes
        return VenuePinViewModel(id: listing.venue.id,
                                 name: listing.venue.name,
                                 latitude: listing.venue.latitude,
                                 longitude: listing.venue.longitude,
                                 glyph: minutes.map { "\($0)" } ?? "?",
                                 color: Theme.waitColor(forMinutes: minutes))
    }

    private static func makePreview(_ listing: VenueListing) -> VenuePreviewViewModel {
        let snapshot = listing.snapshot
        let source: String
        if snapshot.waitMinutes == nil {
            source = "No recent reports. This is not a 0-minute wait."
        } else {
            let relative = RelativeDateTimeFormatter().localizedString(for: snapshot.timestamp, relativeTo: Date())
            source = "\(snapshot.source.rawValue) · \(relative)"
        }
        let queue: String
        switch listing.venue.queueSupport {
        case .demoSupported: queue = "Demo virtual queue available"
        case .closed: queue = "Queue closed"
        case .unsupported: queue = "Remote queue not supported"
        }
        return VenuePreviewViewModel(id: listing.venue.id,
                                     name: listing.venue.name,
                                     subtitle: "\(listing.venue.category.rawValue) · \(listing.venue.address)",
                                     waitText: waitText(for: snapshot),
                                     waitColor: Theme.waitColor(forMinutes: snapshot.waitMinutes),
                                     sourceText: source,
                                     queueText: queue)
    }
}
