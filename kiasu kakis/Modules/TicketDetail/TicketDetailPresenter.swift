import UIKit

final class TicketDetailPresenter: TicketDetailPresenterProtocol {

    weak var view: TicketDetailViewProtocol?
    private let interactor: TicketDetailInteractorProtocol
    private let simulator: QueueSimulating
    private var queueObserver: QueueChangeObserver?

    init(interactor: TicketDetailInteractorProtocol, simulator: QueueSimulating = QueueSimulator.shared) {
        self.interactor = interactor
        self.simulator = simulator
    }

    func viewDidLoad() {
        render()
        queueObserver = QueueChangeObserver { [weak self] in self?.render() }
        refreshTravel(requestPermission: false)
    }

    func didTapProximityAction() { refreshTravel(requestPermission: true) }

    private func refreshTravel(requestPermission: Bool) {
        Task { [weak self] in
            await self?.interactor.refreshTravel(requestPermission: requestPermission)
            self?.render()
        }
    }

    // Compares the trip with what is left of the queue (about 5 minutes a group) so the user knows when to go.
    private func proximity(for ticket: QueueTicket) -> (text: String?, action: String?) {
        if ticket.arrivedAt != nil { return ("You're here. Enjoy!", nil) }
        guard ticket.status == .waiting || ticket.status == .almostYourTurn else { return (nil, nil) }
        if let travel = ticket.travelMinutes {
            let spare = ticket.position * QueueService.minutesPerGroup - travel
            return (spare <= 0 ? "Leave now · \(travel) min away" : "Leave in \(spare) min · \(travel) min away", nil)
        }
        if interactor.locationStatus != .authorized { return ("Want a leave alert?", "Turn on location") }
        return (nil, nil)
    }

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

        // One line under the progress bar. A waiting ticket shows when to leave, other states say what to do.
        let prompt = proximity(for: ticket)
        let message: String
        switch ticket.status {
        case .waiting: message = prompt.text ?? ""
        case .almostYourTurn: message = ticket.arrivedAt == nil ? "You're next. Head over now." : "You're here. You're next!"
        case .called: message = "It's your turn. Go in now."
        case .completed: message = "Done. Enjoy!"
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
            estimateText: isWaiting ? simulator.speed.estimateText(groups: position) : "-",
            partyText: ticket.partySize == 1 ? "1 person" : "\(ticket.partySize) people",
            message: message,
            stepIndex: step,
            // Skipping ahead is a presentation tool, so it hides unless demo controls are on. Finishing a called ticket always shows.
            canAdvance: ticket.status == .called || (ticket.status.isActive && DemoControls.isEnabled),
            advanceTitle: ticket.status == .called ? "Mark as served" : "Skip ahead (demo)",
            canCancel: ticket.status.isActive,
            promptActionTitle: ticket.status == .waiting ? prompt.action : nil))
    }
}
