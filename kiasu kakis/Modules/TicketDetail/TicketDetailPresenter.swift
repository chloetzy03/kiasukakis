import UIKit
import CoreLocation

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

    // After being called this is "I'm here". Otherwise it is the demo's skip-ahead.
    func didTapAdvance() {
        guard let ticket = interactor.ticket else { return }
        // A number from the restaurant's own system: update it by hand while waiting, and finish it once it's up.
        if ticket.isTracked {
            if ticket.status == .called { interactor.advance(); render() } else { view?.askForNowServing(current: ticket.nowServing) }
            return
        }
        guard ticket.status == .called else {
            interactor.advance()
            render()
            return
        }
        // Check the user's location when we can. Someone far away probably tapped by mistake, so ask once.
        Task { [weak self] in
            guard let self else { return }
            if let distance = await interactor.distanceToVenue(), distance > farFromVenueMetres {
                view?.askToConfirmCheckIn(venueName: ticket.venueName, distanceText: Self.distanceText(distance))
            } else {
                didConfirmCheckIn()
            }
        }
    }

    func didEnterNowServing(_ number: Int) {
        interactor.updateNowServing(number)
        render()
    }

    func didConfirmCheckIn() {
        interactor.checkIn()
        render()
    }

    static func distanceText(_ metres: CLLocationDistance) -> String {
        metres < 1000 ? "\(Int((metres / 50).rounded()) * 50) m" : String(format: "%.1f km", metres / 1000)
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

    private func advanceTitle(for ticket: QueueTicket) -> String {
        switch (ticket.isTracked, ticket.status) {
        case (true, .called): return "Done"
        case (true, _): return "Update now serving"
        case (false, .called): return "I'm here"
        default: return "Skip ahead (demo)"
        }
    }

    private func promptAction(for ticket: QueueTicket, locationAction: String?) -> String? {
        switch ticket.status {
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
        case .called: message = ticket.isTracked ? "Your number's up. Go in now." : calledMessage(for: ticket)
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
            estimateText: !isWaiting ? "-" : (ticket.isTracked ? "About \(position * QueueService.minutesPerGroup) min" : simulator.speed.estimateText(groups: position)),
            partyText: ticket.isTracked ? "-" : (ticket.partySize == 1 ? "1 person" : "\(ticket.partySize) people"),
            message: message,
            stepIndex: step,
            // Skipping ahead is a presentation tool, so it hides unless demo controls are on. "I'm here" always shows once called.
            canAdvance: ticket.status == .called || (ticket.status.isActive && (DemoControls.isEnabled || ticket.isTracked)),
            advanceTitle: advanceTitle(for: ticket),
            advanceIsPrimary: ticket.status == .called || ticket.isTracked,
            canCancel: ticket.status.isActive,
            promptActionTitle: promptAction(for: ticket, locationAction: prompt.action)))
    }
}
