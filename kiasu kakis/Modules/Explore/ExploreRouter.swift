import UIKit

// Navigation + module assembly: the only place that knows how the pieces are wired together.
final class ExploreRouter: ExploreRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {
        let view = ExploreViewController()
        let router = ExploreRouter()
        let presenter = ExplorePresenter(interactor: ExploreInteractor(), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return view
    }

    func showVenueDetails(venueID: String, venueName: String) {
        // Replaced by the real Venue Details module in Milestone 3.
        let placeholder = PlaceholderViewController(symbol: "fork.knife",
                                                    heading: venueName,
                                                    message: "Venue details arrive in Milestone 3.")
        placeholder.title = venueName
        placeholder.navigationItem.largeTitleDisplayMode = .never
        viewController?.navigationController?.pushViewController(placeholder, animated: true)
    }
}
