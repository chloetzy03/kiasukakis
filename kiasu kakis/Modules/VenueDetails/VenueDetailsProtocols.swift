import UIKit

// Everything the screen needs, already formatted as text and colours.
struct VenueDetailsViewModel {
    let name: String
    let categoryText: String
    let address: String
    let waitText: String
    let waitColor: UIColor
    let sourceText: String
    let updatedText: String
    let statusSymbol: String
    let statusTitle: String
    let statusMessage: String
    let statusColor: UIColor
    let canJoin: Bool
    let hasActiveTicket: Bool
    let disclaimer: String
    let isSaved: Bool
}

struct TravelViewModel {
    let summary: String
    let hint: String?
    let actionTitle: String?
    let isLoading: Bool
}

// Rating, hours and price from Google, formatted for display. Any line can be missing.
struct PlaceInfoViewModel {
    let ratingText: String?
    let openText: String?
    let isOpen: Bool?
    let priceText: String?
    let todayHoursText: String?
    let attribution: String
}

enum TravelResult {
    case ready(TravelTimes)
    case needsPermission
    case denied
    case unavailable
}

protocol VenueDetailsViewProtocol: AnyObject {
    func show(_ viewModel: VenueDetailsViewModel)
    func showTravel(_ viewModel: TravelViewModel)
    func showPlaceInfo(_ viewModel: PlaceInfoViewModel?)
    func showPhoto(_ image: UIImage?, credit: String?)
}

protocol VenueDetailsPresenterProtocol: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapSave()
    func didTapJoin()
    func didTapOpenInMaps()
    func didTapTravelAction()
}

protocol VenueDetailsInteractorProtocol: AnyObject {
    var venue: Venue { get }
    var snapshot: QueueSnapshot { get }
    var isSaved: Bool { get }
    var activeTicket: QueueTicket? { get }
    func toggleSaved()
    func loadTravel(requestPermission: Bool) async -> TravelResult
    func loadPlaceDetails() async -> PlaceDetails?
    func loadPhoto(for details: PlaceDetails) async -> Data?
}

protocol VenueDetailsRouterProtocol: AnyObject {
    func openInMaps(_ venue: Venue)
    func showJoinQueue(for venue: Venue)
    func showTicket(ticketID: UUID)
    func openSettings()
}
