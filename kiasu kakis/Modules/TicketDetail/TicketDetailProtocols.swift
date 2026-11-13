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
    // True when the button is the main thing to do ("I'm here" after being called).
    let advanceIsPrimary: Bool
    let canCancel: Bool
    // A button under the prompt, for example to turn on location. nil when there is nothing to do.
    let promptActionTitle: String?
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
    func requestMoreTime()
    func checkIn()
    var locationStatus: LocationAuthorization { get }
    func refreshTravel(requestPermission: Bool) async
}
