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
    private var searchedRegions: [MKCoordinateRegion] = []
    private var searchTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?
    private var queueObserver: QueueChangeObserver?
    private var queueRowIDs: [String] = []
    private var suggestions: [PlaceSuggestion] = []
    private static let singaporeCenter = CLLocationCoordinate2D(latitude: 1.2950, longitude: 103.8500)
    // Zoomed out further than this (about 15 km tall), a search would be too broad to be useful.
    private static let maxSearchSpan = 0.15
    private static let searchPadding = 1.5
    // A very long list is no use on a phone, so only the shortest waits are listed.
    private static let maxQueueRows = 40
    // Only food types, since the app is about queues for food. (Attraction stays in the data model for old saved places.)
    private let categories = VenueCategory.allCases.filter { $0 != .attraction }

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
        // Waits change on their own, so refresh the pins and the open card when they do.
        queueObserver = QueueChangeObserver { [weak self] in self?.queueDataChanged() }
    }

    private func queueDataChanged() {
        refresh()
        if let selectedID { view?.showPreview(interactor.listing(id: selectedID).map { makePreview($0) }) }
    }

    // Typing shows matches we already know straight away, then adds Google or Apple Maps suggestions
    // once the user pauses for a moment.
    func didChangeSearch(_ text: String) {
        query = text
        suggestionTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            view?.showSuggestions(nil)
            return
        }
        let center = visibleRegion?.center ?? Self.singaporeCenter
        let local = interactor.localSuggestions(matching: trimmed, near: center)
        suggestions = local
        let needsRemote = SearchText.normalized(trimmed).count >= 2
        view?.showSuggestions(makeSuggestionsModel(isLoading: needsRemote))
        guard needsRemote else { return }
        suggestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            let remote = await interactor.remoteSuggestions(for: trimmed, near: center)
            guard !Task.isCancelled else { return }
            suggestions = Self.merge(local: local, remote: remote)
            view?.showSuggestions(makeSuggestionsModel(isLoading: false))
        }
    }

    func didSelectSuggestion(at index: Int) {
        guard suggestions.indices.contains(index) else { return }
        let suggestion = suggestions[index]
        suggestionTask?.cancel()
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let venue = await interactor.resolve(suggestion) else {
                view?.showMessage(title: "Couldn't open that place", message: "Check your internet connection and try again.")
                return
            }
            query = ""
            suggestions = []
            view?.showSuggestions(nil)
            view?.clearSearchText()
            // Zoom in on the place and select it, so its card opens.
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                                            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))
            visibleRegion = region
            category = nil
            view?.showCategories(["All"] + categories.map(\.rawValue), selectedIndex: 0)
            selectedID = venue.id
            refresh()
            view?.showPreview(interactor.listing(id: venue.id).map { self.makePreview($0) })
            view?.focusMap(on: region)
        }
    }

    // Local matches first, then remote ones that are not already listed.
    static func merge(local: [PlaceSuggestion], remote: [PlaceSuggestion]) -> [PlaceSuggestion] {
        let known = Set(local.map { SearchText.normalized($0.title) })
        return local + remote.filter { !known.contains(SearchText.normalized($0.title)) }
    }

    private func makeSuggestionsModel(isLoading: Bool) -> SuggestionsViewModel {
        let rows = suggestions.map {
            SuggestionRowViewModel(title: $0.title, subtitle: $0.subtitle,
                                   symbolName: $0.category.map { Self.symbolName(for: $0) } ?? "mappin.circle")
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return SuggestionsViewModel(rows: rows,
                                    isLoading: isLoading,
                                    showsGoogleAttribution: suggestions.contains { $0.source == .google },
                                    emptyMessage: rows.isEmpty && !isLoading ? "No places found for “\(trimmed)”." : nil)
    }

    func didSelectCategory(at index: Int) {
        category = index == 0 ? nil : categories[index - 1]
        refresh()
    }

    func viewWillAppear() { queueDataChanged() }

    // Tapping a row in the sheet: move the map to that place and open its summary.
    func didSelectQueueRow(at index: Int) {
        guard queueRowIDs.indices.contains(index) else { return }
        focus(onVenueID: queueRowIDs[index], zoomedIn: false)
    }

    func didTapNearestQueue() {
        let center = visibleRegion?.center ?? Self.singaporeCenter
        let here = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let nearest = interactor.allListings()
            .filter { $0.snapshot.waitMinutes != nil }
            .min { here.distance(from: CLLocation(latitude: $0.venue.latitude, longitude: $0.venue.longitude))
                 < here.distance(from: CLLocation(latitude: $1.venue.latitude, longitude: $1.venue.longitude)) }
        if let nearest { focus(onVenueID: nearest.venue.id, zoomedIn: true) }
    }

    func didTapSheetSave() {
        guard let id = selectedID, let listing = interactor.listing(id: id) else { return }
        interactor.toggleSaved(id)
        view?.showPreview(makePreview(listing))
    }

    func didTapSheetJoin() {
        guard let id = selectedID, let listing = interactor.listing(id: id) else { return }
        if let ticket = interactor.activeTicket(forVenue: id) {
            router.showTicket(id: ticket.id)
        } else if listing.venue.queueSupport == .native {
            router.showJoinQueue(for: listing.venue)
        } else if listing.venue.queueSupport == .external, let url = listing.venue.externalQueueURL {
            router.openExternalQueue(url)
        }
    }

    private func focus(onVenueID id: String, zoomedIn: Bool) {
        guard let listing = interactor.listing(id: id) else { return }
        category = nil
        view?.showCategories(["All"] + categories.map(\.rawValue), selectedIndex: 0)
        let span = zoomedIn ? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            : (visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: listing.venue.latitude,
                                                                       longitude: listing.venue.longitude), span: span)
        visibleRegion = region
        selectedID = id
        refresh()
        view?.showPreview(makePreview(listing))
        view?.focusMap(on: region)
    }

    func didSelectVenue(id: String) {
        selectedID = id
        view?.showPreview(interactor.listing(id: id).map { makePreview($0) })
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
        guard Self.needsSearch(region, searched: searchedRegions) else {
            view?.showAreaStatus(.hidden)
            return
        }
        searchTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await self?.search(region)
        }
    }

    func didTapRetrySearch() {
        guard let region = visibleRegion, region.span.latitudeDelta <= Self.maxSearchSpan else { return }
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in await self?.search(region) }
    }

    @MainActor
    private func search(_ region: MKCoordinateRegion) async {
        view?.showAreaStatus(.searching)
        // Search a wider area than the screen, so a small pan afterwards already has pins.
        let wider = MKCoordinateRegion(center: region.center,
                                       span: MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * Self.searchPadding,
                                                              longitudeDelta: region.span.longitudeDelta * Self.searchPadding))
        do {
            try await interactor.discoverPlaces(in: wider) { [weak self] in self?.refresh() }
            guard !Task.isCancelled else { return }
            searchedRegions.append(wider)
            refresh()
            view?.showAreaStatus(.hidden)
        } catch {
            guard !Task.isCancelled else { return }
            view?.showAreaStatus(.failed)
        }
    }

    // Skip the search if an earlier search already covered what is on screen.
    static func needsSearch(_ region: MKCoordinateRegion, searched: [MKCoordinateRegion]) -> Bool {
        !searched.contains { done in
            let latFits = abs(region.center.latitude - done.center.latitude) + region.span.latitudeDelta / 2 <= done.span.latitudeDelta / 2
            let lonFits = abs(region.center.longitude - done.center.longitude) + region.span.longitudeDelta / 2 <= done.span.longitudeDelta / 2
            // Zoomed in a lot since then? Search again, because the old search only kept the top results.
            let notTooCoarse = done.span.latitudeDelta <= region.span.latitudeDelta * 2.5
            return latFits && lonFits && notTooCoarse
        }
    }

    func didTapInfo() { router.showAbout() }

    func didTapPreview() {
        guard let id = selectedID, let listing = interactor.listing(id: id) else { return }
        router.showVenueDetails(venueID: id, venueName: listing.venue.name)
    }

    private func refresh() {
        let listings: [VenueListing]
        if let visibleRegion {
            listings = interactor.listings(matching: "", category: category, in: visibleRegion)
        } else {
            listings = interactor.listings(matching: "", category: category)
        }
        if let selectedID, !listings.contains(where: { $0.venue.id == selectedID }) {
            self.selectedID = nil
            view?.showPreview(nil)
        }
        view?.showPins(listings.map { Self.makePin($0) }, selectedID: selectedID)

        // The sheet lists only places that have a queue, shortest wait first.
        let queues = listings
            .filter { $0.snapshot.waitMinutes != nil }
            .sorted { ($0.snapshot.waitMinutes ?? 0) < ($1.snapshot.waitMinutes ?? 0) }
        let shown = Array(queues.prefix(Self.maxQueueRows))
        queueRowIDs = shown.map(\.venue.id)
        let tooFarOut = (visibleRegion?.span.latitudeDelta ?? 0) > Self.maxSearchSpan
        view?.showQueueList(makeQueueList(shown, totalCount: queues.count, tooFarOut: tooFarOut))
    }

    private static func queueCountText(shown: Int, total: Int) -> String {
        if total == 0 { return "" }
        if total > shown { return "Shortest \(shown) of \(total)" }
        return total == 1 ? "1 queue" : "\(total) queues"
    }

    private func makeQueueList(_ queues: [VenueListing], totalCount: Int, tooFarOut: Bool) -> QueueListViewModel {
        let rows = queues.map { listing -> QueueRowViewModel in
            let minutes = listing.snapshot.waitMinutes
            let wait = Self.waitText(for: listing.snapshot)
            return QueueRowViewModel(name: listing.venue.name,
                                     subtitle: "\(listing.venue.category.rawValue) · \(listing.venue.address)",
                                     waitText: wait,
                                     badgeColor: Theme.waitColor(forMinutes: minutes),
                                     badgeTextColor: Theme.pinTextColor(forMinutes: minutes),
                                     spoken: "\(listing.venue.name), " + QueueFormatting.spoken(wait) + " wait")
        }
        var empty: QueueListViewModel.Empty?
        if rows.isEmpty {
            empty = tooFarOut
                ? QueueListViewModel.Empty(title: "Zoom in to see queues",
                                           message: "The map is zoomed out too far to show queues.", buttonTitle: nil)
                : QueueListViewModel.Empty(title: "No queues in this area yet",
                                           message: "Kiasu Kakis shows places you can queue at.",
                                           buttonTitle: "Go to nearest queue")
        }
        return QueueListViewModel(title: "Queues in this area",
                                  subtitle: Self.queueCountText(shown: rows.count, total: totalCount),
                                  rows: rows, empty: empty)
    }

    // MARK: - Formatting

    static func waitText(for snapshot: QueueSnapshot) -> String {
        QueueFormatting.waitText(snapshot)
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
                                 isPlaceDot: !listing.venue.isDemo && minutes == nil,
                                 isFeatured: DemoVenueData.curatedIDs.contains(listing.venue.id),
                                 spokenText: "\(listing.venue.name), " + (minutes == nil
                                    ? "no queue information"
                                    : QueueFormatting.spoken(waitText(for: listing.snapshot)) + " wait"))
    }

    private static func symbolName(for category: VenueCategory) -> String {
        switch category {
        case .hawker: return "storefront"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .bar: return "wineglass.fill"
        case .attraction: return "star.fill"
        }
    }

    // Group sizes differ (a table for 2 is quicker than a table for 8), so the count is always "about".
    private func aheadText(for listing: VenueListing) -> String? {
        if let ticket = interactor.activeTicket(forVenue: listing.venue.id), ticket.status.isActive {
            return "Your ticket: \(Self.groupsText(ticket.position, prefix: nil)) ahead of you"
        }
        guard listing.venue.queueSupport == .native, listing.snapshot.waitMinutes != nil else { return nil }
        return Self.groupsText(QueueService.groupsAhead(for: listing.snapshot), prefix: "About") + " ahead"
    }

    private static func groupsText(_ count: Int, prefix: String?) -> String {
        let noun = count == 1 ? "1 group" : "\(count) groups"
        return prefix.map { "\($0) \(noun)" } ?? noun
    }

    private func makePreview(_ listing: VenueListing) -> VenuePreviewViewModel {
        let snapshot = listing.snapshot
        let source: String
        if snapshot.waitMinutes == nil {
            source = "No recent reports. This is not a 0-minute wait."
        } else {
            source = "\(snapshot.source.rawValue) · updated \(QueueFormatting.ago(snapshot.timestamp))"
        }
        let info = QueueSupportInfo(venue: listing.venue)
        let hasTicket = interactor.activeTicket(forVenue: listing.venue.id) != nil
        let queue = info.shortText
        let joinTitle = hasTicket ? "View my ticket" : info.actionTitle
        let canJoin = hasTicket || info.canAct
        return VenuePreviewViewModel(id: listing.venue.id,
                                     name: listing.venue.name,
                                     subtitle: "\(listing.venue.category.rawValue) · \(listing.venue.address)",
                                     waitText: Self.waitText(for: snapshot),
                                     waitColor: Theme.waitColor(forMinutes: snapshot.waitMinutes),
                                     sourceText: source,
                                     queueText: queue,
                                     joinTitle: joinTitle,
                                     canJoin: canJoin,
                                     isSaved: interactor.isSaved(listing.venue.id),
                                     aheadText: aheadText(for: listing))
    }
}
