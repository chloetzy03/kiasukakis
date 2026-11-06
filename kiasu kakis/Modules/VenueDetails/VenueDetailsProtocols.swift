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
    let isSaved: Bool
}

struct TravelViewModel {
    let summary: String
    let hint: String?
    let actionTitle: String?
    let isLoading: Bool
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
}

protocol VenueDetailsRouterProtocol: AnyObject {
    func openInMaps(_ venue: Venue)
    func showJoinQueue(for venue: Venue)
    func showTicket(ticketID: UUID)
    func openSettings()
}
