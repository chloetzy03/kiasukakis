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
        if ticket.arrivedAt != nil { return ("You've checked in. Enjoy your meal!", nil) }
        guard ticket.status == .waiting || ticket.status == .almostYourTurn else { return (nil, nil) }
        if let travel = ticket.travelMinutes {
            let wait = ticket.position * QueueService.minutesPerGroup
            let spare = wait - travel
            let text = spare <= 0
                ? "Leave now. It takes about \(travel) min to get there."
                : "It takes about \(travel) min to get there. Leave in about \(spare) min."
            // The demo queue runs much faster than real time, so say so.
            return (simulator.speed == .demo ? text + " Demo mode runs faster than real life." : text, nil)
        }
        if interactor.locationStatus != .authorized {
            return ("Turn on location and we'll alert you when it's time to leave.", "Allow location")
        }
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
            summaryText: isWaiting ? "\(positionText) · \(simulator.speed.estimateText(groups: position))" : positionText,
            footnoteText: String(format: "Now serving #%03d · ", ticket.nowServing) + (ticket.partySize == 1 ? "1 person" : "\(ticket.partySize) people"),
            message: message,
            stepIndex: step,
            // Skipping ahead is a presentation tool, so it hides unless demo controls are on. Finishing a called ticket always shows.
            canAdvance: ticket.status == .called || (ticket.status.isActive && DemoControls.isEnabled),
            advanceTitle: ticket.status == .called ? "Mark as served" : "Skip ahead (demo)",
            canCancel: ticket.status.isActive,
            proximityText: proximity(for: ticket).text,
            proximityActionTitle: proximity(for: ticket).action))
    }
}
