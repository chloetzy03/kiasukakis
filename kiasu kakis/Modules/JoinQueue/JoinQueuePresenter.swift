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
        }
    }

    func didTapClose() { router.close() }

    private func render() {
        let venue = interactor.venue
        let snapshot = interactor.snapshot
        let ahead = QueueService.groupsAhead(for: snapshot)
        let canJoin = venue.queueSupport == .demoSupported

        view?.show(JoinQueueViewModel(
            venueName: venue.name,
            waitText: snapshot.waitMinutes.map { "\($0) min" } ?? "No recent reports",
            waitColor: Theme.waitColor(forMinutes: snapshot.waitMinutes),
            aheadText: "About \(ahead) groups ahead",
            sourceText: "Source: \(snapshot.source.rawValue)",
            partySizeText: partySize == 1 ? "1 person" : "\(partySize) people",
            canJoin: canJoin,
            unavailableMessage: canJoin ? nil : "This venue isn't accepting demo tickets."))
    }
}
