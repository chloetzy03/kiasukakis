import UIKit
import MapKit

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
    func didTapInfo()
}

protocol ExploreInteractorProtocol: AnyObject {
    func listings(matching query: String, category: VenueCategory?) -> [VenueListing]
    func listing(id: String) -> VenueListing?
    @MainActor func discoverPlaces(in region: MKCoordinateRegion, onProgress: () -> Void) async throws
    func listings(matching query: String, category: VenueCategory?, in region: MKCoordinateRegion) -> [VenueListing]
}

protocol ExploreRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String, venueName: String)
    func showAbout()
}
