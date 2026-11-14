import UIKit
import MapKit
import CoreLocation

// What the screen needs to show a map pin.
struct VenuePinViewModel: Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let labelText: String
    let symbolName: String?
    let fillColor: UIColor
    let textColor: UIColor
    // Real places with no queue data are drawn as small grey dots instead of pills.
    let isPlaceDot: Bool
    // The hand-picked places stay visible when pins crowd together. The others make room for them.
    let isFeatured: Bool
    // What VoiceOver reads, for example "Golden Bowl, 15 min rising".
    let spokenText: String
}

// What the bottom preview card shows.
struct VenuePreviewViewModel {
    let id: String
    let name: String
    let subtitle: String
    let waitText: String
    let waitColor: UIColor
    let sourceText: String
    let queueText: String
    let joinTitle: String
    let canJoin: Bool
    let isSaved: Bool
    // For example "About 3 groups ahead". nil when the place has no queue we can count.
    let aheadText: String?
}

// One row in the sheet's list of queues.
struct QueueRowViewModel: Equatable {
    let name: String
    let subtitle: String
    let waitText: String
    let badgeColor: UIColor
    let badgeTextColor: UIColor
    let spoken: String
}

struct QueueListViewModel: Equatable {
    struct Empty: Equatable {
        let title: String
        let message: String
        let buttonTitle: String?
    }
    let title: String
    let subtitle: String
    let rows: [QueueRowViewModel]
    // Set when nothing in view has a queue.
    let empty: Empty?
}

// One row in the search results list.
struct SuggestionRowViewModel: Equatable {
    let title: String
    let subtitle: String
    let symbolName: String
}

// Everything the results list needs. Passing nil to the view hides the list.
struct SuggestionsViewModel: Equatable {
    let rows: [SuggestionRowViewModel]
    let isLoading: Bool
    let showsGoogleAttribution: Bool
    let emptyMessage: String?
}

struct VenueListing {
    let venue: Venue
    let snapshot: QueueSnapshot
}

// What the small status pill under the search bar says.
enum AreaStatus: Equatable {
    case hidden
    case searching
    case zoomIn
    case failed
}

// VIPER contracts: each piece only knows the others through these protocols.
protocol ExploreViewProtocol: AnyObject {
    func showCategories(_ titles: [String], selectedIndex: Int)
    func showPins(_ pins: [VenuePinViewModel], selectedID: String?)
    func showPreview(_ preview: VenuePreviewViewModel?)
    func showQueueList(_ model: QueueListViewModel)
    func showOfflineBanner(_ isVisible: Bool)
    func showAreaStatus(_ status: AreaStatus)
    func showSuggestions(_ viewModel: SuggestionsViewModel?)
    func clearSearchText()
    func focusMap(on region: MKCoordinateRegion)
    func showMessage(title: String, message: String)
}

protocol ExplorePresenterProtocol: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didChangeSearch(_ text: String)
    func didSelectCategory(at index: Int)
    func didSelectVenue(id: String)
    func didDeselectVenue()
    func didTapPreview()
    func didSelectQueueRow(at index: Int)
    func didTapSheetJoin()
    func didTapSheetSave()
    func didTapNearestQueue()
    func didChangeRegion(_ region: MKCoordinateRegion)
    func didTapRetrySearch()
    func didSelectSuggestion(at index: Int)
    func didTapInfo()
}

protocol ExploreInteractorProtocol: AnyObject {
    func listings(matching query: String, category: VenueCategory?) -> [VenueListing]
    func listing(id: String) -> VenueListing?
    func allListings() -> [VenueListing]
    func activeTicket(forVenue venueID: String) -> QueueTicket?
    func isSaved(_ venueID: String) -> Bool
    func toggleSaved(_ venueID: String)
    @MainActor func discoverPlaces(in region: MKCoordinateRegion, onProgress: () -> Void) async throws
    func listings(matching query: String, category: VenueCategory?, in region: MKCoordinateRegion) -> [VenueListing]
    func localSuggestions(matching query: String, near center: CLLocationCoordinate2D) -> [PlaceSuggestion]
    func remoteSuggestions(for query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion]
    func resolve(_ suggestion: PlaceSuggestion) async -> Venue?
    func submitReport(minutes: Int, for venue: Venue)
}

protocol ExploreRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String, venueName: String)
    func showAbout()
    func showJoinQueue(for venue: Venue)
    func showTicket(id: UUID)
    func openExternalQueue(_ url: URL)
    func showReportOptions(venueName: String, onPick: @escaping (CrowdReportOption) -> Void)
}
