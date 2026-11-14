import UIKit

final class MyQueuesPresenter: MyQueuesPresenterProtocol {

    weak var view: MyQueuesViewProtocol?
    private let interactor: MyQueuesInteractorProtocol
    private let router: MyQueuesRouterProtocol
    private var queueObserver: QueueChangeObserver?

    init(interactor: MyQueuesInteractorProtocol, router: MyQueuesRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewWillAppear() {
        if queueObserver == nil { queueObserver = QueueChangeObserver { [weak self] in self?.viewWillAppear() } }
        let tickets = interactor.tickets
        let active = tickets.filter { $0.status.isActive }
        let past = tickets.filter { !$0.status.isActive }

        var sections: [TicketSectionViewModel] = []
        if !active.isEmpty { sections.append(TicketSectionViewModel(title: "Active", rows: active.map { makeRow($0) })) }
        if !past.isEmpty { sections.append(TicketSectionViewModel(title: "Past", rows: past.map { makeRow($0) })) }

        view?.show(sections: sections)
        view?.showEmptyState(tickets.isEmpty)
    }

    func didSelectTicket(id: UUID) { router.showTicket(id: id) }

    func didDeleteTicket(id: UUID) {
        interactor.deleteTicket(id: id)
        viewWillAppear()
    }

    // Lets people save a place they already queued at, without searching for it again.
    func didToggleSaved(ticketID: UUID) {
        guard let ticket = interactor.tickets.first(where: { $0.id == ticketID }) else { return }
        interactor.toggleSaved(venueID: ticket.venueID)
        viewWillAppear()
    }

    private func makeRow(_ ticket: QueueTicket) -> TicketRowViewModel {
        var detail = "\(ticket.status.rawValue)"
        switch ticket.status {
        case .waiting, .almostYourTurn:
            detail += ticket.position == 1 ? " · 1 group ahead" : " · \(ticket.position) groups ahead"
        default: break
        }
        return TicketRowViewModel(id: ticket.id,
                                  title: ticket.venueName,
                                  subtitle: (ticket.isTracked ? "Number " : "Ticket ") + String(format: "#%03d", ticket.ticketNumber) + " · " + detail,
                                  statusColor: Theme.color(for: ticket.status),
                                  canDelete: !ticket.status.isActive,
                                  isSaved: interactor.isSaved(venueID: ticket.venueID))
    }
}
