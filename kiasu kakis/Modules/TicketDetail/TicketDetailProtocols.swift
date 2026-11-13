import UIKit

struct TicketDetailViewModel {
    let venueName: String
    let ticketNumberText: String
    let statusText: String
    let statusColor: UIColor
    // For example "6 groups ahead of you · About 30 min".
    let summaryText: String
    // For example "Now serving #052 · 2 people". Small print.
    let footnoteText: String
    let message: String
    let stepIndex: Int?
    let canAdvance: Bool
    let advanceTitle: String
    let canCancel: Bool
    // The "getting there" card. Hidden when there is nothing useful to say.
    let proximityText: String?
    let proximityActionTitle: String?
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
    func didTapProximityAction()
}

protocol TicketDetailInteractorProtocol: AnyObject {
    var ticket: QueueTicket? { get }
    func advance()
    func cancel()
    var locationStatus: LocationAuthorization { get }
    func refreshTravel(requestPermission: Bool) async
}
