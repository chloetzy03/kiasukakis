import UIKit

struct JoinQueueViewModel {
    let venueName: String
    let waitText: String
    let waitColor: UIColor
    let aheadText: String
    let sourceText: String
    let partySizeText: String
    // The most people one group can have at this venue, and the table that group would get.
    let maxPartySize: Int
    let tableText: String
    let canJoin: Bool
    let unavailableMessage: String?
}

protocol JoinQueueViewProtocol: AnyObject {
    func show(_ viewModel: JoinQueueViewModel)
    func showError(_ message: String)
}

protocol JoinQueuePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didChangePartySize(_ size: Int)
    func didTapConfirm()
    func didTapClose()
}

protocol JoinQueueInteractorProtocol: AnyObject {
    var venue: Venue { get }
    var snapshot: QueueSnapshot { get }
    var config: VenueQueueConfig { get }
    // Set when the person is already in as many queues as allowed (and not in this one).
    var queueLimitMessage: String? { get }
    func join(partySize: Int) -> Result<QueueTicket, QueueError>
}

protocol JoinQueueRouterProtocol: AnyObject {
    func close()
    func finish(withTicketID ticketID: UUID)
}
