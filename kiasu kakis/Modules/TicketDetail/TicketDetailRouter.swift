import UIKit

final class TicketDetailRouter {

    static func createModule(ticketID: UUID) -> UIViewController {
        let view = TicketDetailViewController()
        let presenter = TicketDetailPresenter(interactor: TicketDetailInteractor(ticketID: ticketID))
        presenter.view = view
        view.presenter = presenter
        return view
    }
}
