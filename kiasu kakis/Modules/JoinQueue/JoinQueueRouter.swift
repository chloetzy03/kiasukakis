import UIKit

final class JoinQueueRouter: JoinQueueRouterProtocol {

    weak var viewController: UIViewController?
    private let onTicketReady: (UUID) -> Void

    init(onTicketReady: @escaping (UUID) -> Void) {
        self.onTicketReady = onTicketReady
    }

    // Returns a sheet ready to be presented. onTicketReady runs after the sheet closes.
    static func createModule(venue: Venue, onTicketReady: @escaping (UUID) -> Void) -> UIViewController {
        let view = JoinQueueViewController()
        let router = JoinQueueRouter(onTicketReady: onTicketReady)
        let presenter = JoinQueuePresenter(interactor: JoinQueueInteractor(venue: venue), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view

        let nav = UINavigationController(rootViewController: view)
        nav.modalPresentationStyle = .pageSheet
        nav.sheetPresentationController?.detents = [.large()]
        return nav
    }

    func close() { viewController?.dismiss(animated: true) }

    func finish(withTicketID ticketID: UUID) {
        let callback = onTicketReady
        viewController?.dismiss(animated: true) { callback(ticketID) }
    }
}
