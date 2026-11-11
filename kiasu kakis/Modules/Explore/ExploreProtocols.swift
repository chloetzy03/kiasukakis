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
    func showEmptyState(_ message: String?)
    func showOfflineBanner(_ isVisible: Bool)
    func showAreaStatus(_ status: AreaStatus)
    func showSuggestions(_ viewModel: SuggestionsViewModel?)
    func clearSearchText()
    func focusMap(on region: MKCoordinateRegion)
    func showMessage(title: String, message: String)
}

protocol ExplorePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didChangeSearch(_ text: String)
    func didSelectCategory(at index: Int)
    func didSelectVenue(id: String)
    func didDeselectVenue()
    func didTapPreview()
    func didChangeRegion(_ region: MKCoordinateRegion)
    func didTapRetrySearch()
    func didSelectSuggestion(at index: Int)
    func didTapInfo()
}

protocol ExploreInteractorProtocol: AnyObject {
    func listings(matching query: String, category: VenueCategory?) -> [VenueListing]
    func listing(id: String) -> VenueListing?
    @MainActor func discoverPlaces(in region: MKCoordinateRegion, onProgress: () -> Void) async throws
    func listings(matching query: String, category: VenueCategory?, in region: MKCoordinateRegion) -> [VenueListing]
    func localSuggestions(matching query: String, near center: CLLocationCoordinate2D) -> [PlaceSuggestion]
    func remoteSuggestions(for query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion]
    func resolve(_ suggestion: PlaceSuggestion) async -> Venue?
}

protocol ExploreRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String, venueName: String)
    func showAbout()
}
