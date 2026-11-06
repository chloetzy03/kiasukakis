import UIKit

final class MyQueuesPresenter: MyQueuesPresenterProtocol {

    weak var view: MyQueuesViewProtocol?
    private let interactor: MyQueuesInteractorProtocol
    private let router: MyQueuesRouterProtocol

    init(interactor: MyQueuesInteractorProtocol, router: MyQueuesRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewWillAppear() {
        let tickets = interactor.tickets
        let active = tickets.filter { $0.status.isActive }
        let past = tickets.filter { !$0.status.isActive }

        var sections: [TicketSectionViewModel] = []
        if !active.isEmpty { sections.append(TicketSectionViewModel(title: "Active", rows: active.map { Self.makeRow($0) })) }
        if !past.isEmpty { sections.append(TicketSectionViewModel(title: "Past", rows: past.map { Self.makeRow($0) })) }

        view?.show(sections: sections)
        view?.showEmptyState(tickets.isEmpty)
    }

    func didSelectTicket(id: UUID) { router.showTicket(id: id) }

    private static func makeRow(_ ticket: QueueTicket) -> TicketRowViewModel {
        var detail = "\(ticket.status.rawValue)"
        switch ticket.status {
        case .waiting, .almostYourTurn:
            detail += ticket.position == 1 ? " · 1 group ahead" : " · \(ticket.position) groups ahead"
        default: break
        }
        return TicketRowViewModel(id: ticket.id,
                                  title: ticket.venueName,
                                  subtitle: "Ticket " + String(format: "#%03d", ticket.ticketNumber) + " · " + detail,
                                  statusColor: Theme.color(for: ticket.status))
    }
}
