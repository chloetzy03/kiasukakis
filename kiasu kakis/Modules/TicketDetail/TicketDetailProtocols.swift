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
}

protocol TicketDetailInteractorProtocol: AnyObject {
    var ticket: QueueTicket? { get }
    func advance()
    func cancel()
}
