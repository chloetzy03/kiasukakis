import UIKit

final class SavedRouter: SavedRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {
        let view = SavedViewController()
        let router = SavedRouter()
        let presenter = SavedPresenter(interactor: SavedInteractor(), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return view
    }

    func showVenueDetails(venueID: String) {
        guard let venue = VenueRepository.shared.venue(id: venueID) else { return }
        let details = VenueDetailsRouter.createModule(venue: venue)
        viewController?.navigationController?.pushViewController(details, animated: true)
    }
}
