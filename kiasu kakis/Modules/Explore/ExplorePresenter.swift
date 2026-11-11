import UIKit
import MapKit

// Glue: reacts to user actions, asks the interactor for data, formats it for the view.
final class ExplorePresenter: ExplorePresenterProtocol {

    weak var view: ExploreViewProtocol?
    private let interactor: ExploreInteractorProtocol
    private let router: ExploreRouterProtocol
    private let networkMonitor: NetworkMonitoring

    private var query = ""
    private var category: VenueCategory?
    private var selectedID: String?
    private var visibleRegion: MKCoordinateRegion?
    private var lastSearchedRegion: MKCoordinateRegion?
    private var searchTask: Task<Void, Never>?
    // Zoomed out further than this (about 15 km tall), a search would be too broad to be useful.
    private static let maxSearchSpan = 0.15
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

    // Called every time the map stops moving. We show what is already known right away,
    // then search Apple Maps once the user has stopped panning for a moment.
    func didChangeRegion(_ region: MKCoordinateRegion) {
        visibleRegion = region
        refresh()
        searchTask?.cancel()
        guard region.span.latitudeDelta <= Self.maxSearchSpan else {
            view?.showAreaStatus(.zoomIn)
            return
        }
        guard Self.needsSearch(region, lastSearched: lastSearchedRegion) else {
            view?.showAreaStatus(.hidden)
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await self?.search(region)
        }
    }

    func didTapRetrySearch() {
        guard let region = visibleRegion, region.span.latitudeDelta <= Self.maxSearchSpan else { return }
        searchTask?.cancel()
        searchTask = Task { [weak self] in await self?.search(region) }
    }

    private func search(_ region: MKCoordinateRegion) async {
        view?.showAreaStatus(.searching)
        do {
            _ = try await interactor.discoverPlaces(in: region)
            guard !Task.isCancelled else { return }
            lastSearchedRegion = region
            refresh()
            view?.showAreaStatus(.hidden)
        } catch {
            guard !Task.isCancelled else { return }
            view?.showAreaStatus(.failed)
        }
    }

    // Skip the search if the map barely moved since the last one.
    static func needsSearch(_ region: MKCoordinateRegion, lastSearched: MKCoordinateRegion?) -> Bool {
        guard let last = lastSearched else { return true }
        let moved = max(abs(region.center.latitude - last.center.latitude) / region.span.latitudeDelta,
                        abs(region.center.longitude - last.center.longitude) / region.span.longitudeDelta)
        let zoomRatio = region.span.latitudeDelta / last.span.latitudeDelta
        return moved > 0.3 || zoomRatio < 0.6 || zoomRatio > 1.6
    }

    func didTapInfo() { router.showAbout() }

    func didTapPreview() {
        guard let id = selectedID, let listing = interactor.listing(id: id) else { return }
        router.showVenueDetails(venueID: id, venueName: listing.venue.name)
    }

    private func refresh() {
        let listings: [VenueListing]
        if let visibleRegion {
            listings = interactor.listings(matching: query, category: category, in: visibleRegion)
        } else {
            listings = interactor.listings(matching: query, category: category)
        }
        if let selectedID, !listings.contains(where: { $0.venue.id == selectedID }) {
            self.selectedID = nil
            view?.showPreview(nil)
        }
        view?.showPins(listings.map { Self.makePin($0) }, selectedID: selectedID)
        view?.showEmptyState(listings.isEmpty ? "No places found here. Try moving or zooming the map." : nil)
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
                                 labelText: minutes.map { "\($0)m" } ?? "?",
                                 symbolName: Self.symbolName(for: listing.venue.category),
                                 fillColor: Theme.waitColor(forMinutes: minutes),
                                 textColor: Theme.pinTextColor(forMinutes: minutes),
                                 isPlaceDot: !listing.venue.isDemo && minutes == nil)
    }

    private static func symbolName(for category: VenueCategory) -> String {
        switch category {
        case .hawker: return "storefront"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .attraction: return "star.fill"
        }
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
        case .demoSupported: queue = "Virtual queue available"
        case .closed: queue = "Queue closed"
        case .unsupported: queue = listing.venue.isDemo ? "Remote queue not supported" : "Real place from Apple Maps · no queue data"
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
