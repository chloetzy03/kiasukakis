import UIKit

// What the screen needs to show a map pin.
struct VenuePinViewModel: Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let glyph: String
    let color: UIColor
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

// VIPER contracts: each piece only knows the others through these protocols.
protocol ExploreViewProtocol: AnyObject {
    func showCategories(_ titles: [String], selectedIndex: Int)
    func showPins(_ pins: [VenuePinViewModel], selectedID: String?)
    func showPreview(_ preview: VenuePreviewViewModel?)
    func showEmptyState(_ message: String?)
    func showOfflineBanner(_ isVisible: Bool)
}

protocol ExplorePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didChangeSearch(_ text: String)
    func didSelectCategory(at index: Int)
    func didSelectVenue(id: String)
    func didDeselectVenue()
    func didTapPreview()
}

protocol ExploreInteractorProtocol: AnyObject {
    func listings(matching query: String, category: VenueCategory?) -> [VenueListing]
    func listing(id: String) -> VenueListing?
}

protocol ExploreRouterProtocol: AnyObject {
    func showVenueDetails(venueID: String, venueName: String)
}
