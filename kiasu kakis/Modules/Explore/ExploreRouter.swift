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

    func showAbout() {
        let nav = UINavigationController(rootViewController: AboutViewController())
        nav.sheetPresentationController?.detents = [.medium(), .large()]
        viewController?.present(nav, animated: true)
    }

    func showVenueDetails(venueID: String, venueName: String) {
        guard let venue = VenueRepository.shared.venue(id: venueID) else { return }
        let details = VenueDetailsRouter.createModule(venue: venue)
        viewController?.navigationController?.pushViewController(details, animated: true)
    }
}
