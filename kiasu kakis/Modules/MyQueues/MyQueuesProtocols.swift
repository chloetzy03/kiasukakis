import UIKit

struct TicketRowViewModel {
    let id: UUID
    let title: String
    let subtitle: String
    let statusColor: UIColor
    // Only finished tickets can be deleted. Any ticket's place can be saved.
    let canDelete: Bool
    let isSaved: Bool
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
    func didDeleteTicket(id: UUID)
    func didToggleSaved(ticketID: UUID)
}

protocol MyQueuesInteractorProtocol: AnyObject {
    var tickets: [QueueTicket] { get }
    func deleteTicket(id: UUID)
    func isSaved(venueID: String) -> Bool
    func toggleSaved(venueID: String)
}

protocol MyQueuesRouterProtocol: AnyObject {
    func showTicket(id: UUID)
}
