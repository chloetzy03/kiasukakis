import UIKit

final class JoinQueuePresenter: JoinQueuePresenterProtocol {

    weak var view: JoinQueueViewProtocol?
    private let interactor: JoinQueueInteractorProtocol
    private let router: JoinQueueRouterProtocol
    private var partySize = 1

    init(interactor: JoinQueueInteractorProtocol, router: JoinQueueRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() { render() }

    func didChangePartySize(_ size: Int) {
        partySize = size
        render()
    }

    func didTapConfirm() {
        switch interactor.join(partySize: partySize) {
        case .success(let ticket):
            router.finish(withTicketID: ticket.id)
        case .failure(.alreadyJoined(let existing)):
            // Never create a duplicate: open the ticket the user already has.
            router.finish(withTicketID: existing.id)
        case .failure(.notAvailable):
            view?.showError("This queue isn't accepting tickets right now.")
        case .failure(.tooManyActive):
            view?.showError(interactor.queueLimitMessage ?? "You're already in the most queues allowed.")
        }
    }

    func didTapClose() { router.close() }

    private func render() {
        let venue = interactor.venue
        let snapshot = interactor.snapshot
        let ahead = QueueService.groupsAhead(for: snapshot)
        let limitMessage = interactor.queueLimitMessage
        let canJoin = venue.queueSupport == .native && limitMessage == nil

        view?.show(JoinQueueViewModel(
            venueName: venue.name,
            waitText: QueueFormatting.waitText(snapshot),
            waitColor: Theme.waitColor(forMinutes: snapshot.waitMinutes),
            aheadText: "About \(ahead) groups ahead",
            sourceText: "Source: \(snapshot.source.rawValue)",
            partySizeText: partySize == 1 ? "1 person" : "\(partySize) people",
            canJoin: canJoin,
            unavailableMessage: canJoin ? nil : (limitMessage ?? "This venue isn't accepting tickets right now.")))
    }
}
