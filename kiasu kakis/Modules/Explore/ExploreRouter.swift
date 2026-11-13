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
        // Full height, so it reads as its own page and not a second sheet on top of the queue sheet.
        nav.sheetPresentationController?.detents = [.large()]
        viewController?.present(nav, animated: true)
    }

    func showJoinQueue(for venue: Venue) {
        let join = JoinQueueRouter.createModule(venue: venue) { [weak self] ticketID in
            self?.showTicket(id: ticketID)
        }
        viewController?.present(join, animated: true)
    }

    func showTicket(id: UUID) {
        (viewController?.tabBarController as? MainTabBarController)?.showTicket(id)
    }

    func showVenueDetails(venueID: String, venueName: String) {
        guard let venue = VenueRepository.shared.venue(id: venueID) else { return }
        let details = VenueDetailsRouter.createModule(venue: venue)
        viewController?.navigationController?.pushViewController(details, animated: true)
    }
}
