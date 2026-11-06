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
        guard let venue = DemoVenueData.venues.first(where: { $0.id == venueID }) else { return }
        let details = VenueDetailsRouter.createModule(venue: venue)
        viewController?.navigationController?.pushViewController(details, animated: true)
    }
}
