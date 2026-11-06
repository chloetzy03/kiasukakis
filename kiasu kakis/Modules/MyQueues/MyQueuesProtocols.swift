import UIKit

struct TicketRowViewModel {
    let id: UUID
    let title: String
    let subtitle: String
    let statusColor: UIColor
}

struct TicketSectionViewModel {
    let title: String
    let rows: [TicketRowViewModel]
}

protocol MyQueuesViewProtocol: AnyObject {
    func show(sections: [TicketSectionViewModel])
    func showEmptyState(_ isEmpty: Bool)
}

protocol MyQueuesPresenterProtocol: AnyObject {
    func viewWillAppear()
    func didSelectTicket(id: UUID)
}

protocol MyQueuesInteractorProtocol: AnyObject {
    var tickets: [QueueTicket] { get }
}

protocol MyQueuesRouterProtocol: AnyObject {
    func showTicket(id: UUID)
}
