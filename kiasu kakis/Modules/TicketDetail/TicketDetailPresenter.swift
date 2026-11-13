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

    // The one button under the prompt: more time when called, or location for a leave alert.
    func didTapProximityAction() {
        if interactor.ticket?.status == .called {
            interactor.requestMoreTime()
            render()
        } else {
            refreshTravel(requestPermission: true)
        }
    }

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

    // After being called this is "I'm here". Otherwise it is the demo's skip-ahead.
    func didTapAdvance() {
        if interactor.ticket?.status == .called { interactor.checkIn() } else { interactor.advance() }
        render()
    }

    func didTapCancel() { view?.askToConfirmCancel() }

    func didConfirmCancel() {
        interactor.cancel()
        render()
    }

    // "Your turn · 8 min left". The countdown refreshes with every queue tick.
    private func calledMessage(for ticket: QueueTicket) -> String {
        guard let deadline = ticket.deadline(grace: simulator.speed.graceSeconds) else { return "Your turn" }
        let left = deadline.timeIntervalSinceNow * simulator.speed.displayScale
        return "Your turn · \(QueueFormatting.remaining(left)) left"
    }

    private func promptAction(for ticket: QueueTicket, locationAction: String?) -> String? {
        switch ticket.status {
        case .called: return ticket.canRequestMoreTime ? "Running late? \(simulator.speed.extraTimeText)" : nil
        case .waiting: return locationAction
        default: return nil
        }
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
        case .called: message = calledMessage(for: ticket)
        case .completed: message = "Done. Enjoy!"
        case .cancelled: message = "You left this queue."
        case .expired: message = "You missed your turn. Spot released."
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
            // Skipping ahead is a presentation tool, so it hides unless demo controls are on. "I'm here" always shows once called.
            canAdvance: ticket.status == .called || (ticket.status.isActive && DemoControls.isEnabled),
            advanceTitle: ticket.status == .called ? "I'm here" : "Skip ahead (demo)",
            advanceIsPrimary: ticket.status == .called,
            canCancel: ticket.status.isActive,
            promptActionTitle: promptAction(for: ticket, locationAction: prompt.action)))
    }
}
