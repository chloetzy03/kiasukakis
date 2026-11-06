import UIKit

final class MyQueuesRouter: MyQueuesRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {
        let view = MyQueuesViewController()
        let router = MyQueuesRouter()
        let presenter = MyQueuesPresenter(interactor: MyQueuesInteractor(), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return view
    }

    func showTicket(id: UUID) {
        let detail = TicketDetailRouter.createModule(ticketID: id)
        viewController?.navigationController?.pushViewController(detail, animated: true)
    }
}
