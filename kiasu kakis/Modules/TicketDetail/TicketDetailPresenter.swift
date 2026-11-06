import UIKit

final class TicketDetailPresenter: TicketDetailPresenterProtocol {

    weak var view: TicketDetailViewProtocol?
    private let interactor: TicketDetailInteractorProtocol

    init(interactor: TicketDetailInteractorProtocol) {
        self.interactor = interactor
    }

    func viewDidLoad() { render() }

    func didTapAdvance() {
        interactor.advance()
        render()
    }

    func didTapCancel() { view?.askToConfirmCancel() }

    func didConfirmCancel() {
        interactor.cancel()
        render()
    }

    private func render() {
        guard let ticket = interactor.ticket else { return }
        let position = ticket.position
        let isWaiting = ticket.status == .waiting || ticket.status == .almostYourTurn

        let positionText: String
        switch ticket.status {
        case .waiting, .almostYourTurn: positionText = position == 1 ? "1 group ahead of you" : "\(position) groups ahead of you"
        case .called: positionText = "It's your turn"
        default: positionText = "Not in queue"
        }

        let message: String
        switch ticket.status {
        case .waiting: message = "You're in the queue. Head over when you're close to being called."
        case .almostYourTurn: message = "Almost your turn! Start heading to the venue."
        case .called: message = "It's your turn! Please go to the venue now."
        case .completed: message = "Ticket completed. Enjoy!"
        case .cancelled: message = "You left this queue."
        case .expired: message = "This ticket expired."
        }

        let step: Int?
        switch ticket.status {
        case .waiting: step = 0
        case .almostYourTurn: step = 1
        case .called: step = 2
        case .completed: step = 3
        default: step = nil
        }

        view?.show(TicketDetailViewModel(
            venueName: ticket.venueName,
            ticketNumberText: String(format: "#%03d", ticket.ticketNumber),
            statusText: ticket.status.rawValue,
            statusColor: Theme.color(for: ticket.status),
            positionText: positionText,
            nowServingText: String(format: "#%03d", ticket.nowServing),
            estimateText: isWaiting ? "About \(position * QueueService.minutesPerGroup) min" : "-",
            partyText: ticket.partySize == 1 ? "1 person" : "\(ticket.partySize) people",
            message: message,
            stepIndex: step,
            canAdvance: ticket.status.isActive,
            advanceTitle: ticket.status == .called ? "Demo: mark as served" : "Demo: advance the queue",
            canCancel: ticket.status.isActive))
    }
}
