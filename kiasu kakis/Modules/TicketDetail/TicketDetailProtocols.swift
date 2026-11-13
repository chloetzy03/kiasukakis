import UIKit

struct TicketDetailViewModel {
    let venueName: String
    let ticketNumberText: String
    let statusText: String
    let statusColor: UIColor
    let positionText: String
    let nowServingText: String
    let estimateText: String
    let partyText: String
    let message: String
    let stepIndex: Int?
    let canAdvance: Bool
    let advanceTitle: String
    let canCancel: Bool
    // The "getting there" card. Hidden when there is nothing useful to say.
    let proximityText: String?
    let proximityActionTitle: String?
    let canCheckIn: Bool
}

protocol TicketDetailViewProtocol: AnyObject {
    func show(_ viewModel: TicketDetailViewModel)
    func askToConfirmCancel()
}

protocol TicketDetailPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapAdvance()
    func didTapCancel()
    func didConfirmCancel()
    func didTapCheckIn()
    func didTapProximityAction()
}

protocol TicketDetailInteractorProtocol: AnyObject {
    var ticket: QueueTicket? { get }
    func advance()
    func cancel()
    func checkIn()
    var locationStatus: LocationAuthorization { get }
    func refreshTravel(requestPermission: Bool) async
}
