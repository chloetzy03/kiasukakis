import UIKit
import MapKit

final class VenueDetailsRouter: VenueDetailsRouterProtocol {

    weak var viewController: UIViewController?

    static func createModule(venue: Venue) -> UIViewController {
        let view = VenueDetailsViewController()
        let router = VenueDetailsRouter()
        let presenter = VenueDetailsPresenter(interactor: VenueDetailsInteractor(venue: venue), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return view
    }

    func openInMaps(_ venue: Venue) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: venue.latitude,
                                                                                       longitude: venue.longitude)))
        item.name = venue.name
        item.openInMaps()
    }

    func showJoinQueue(for venue: Venue) {
        let join = JoinQueueRouter.createModule(venue: venue) { [weak self] ticketID in
            self?.showTicket(ticketID: ticketID)
        }
        viewController?.present(join, animated: true)
    }

    func openExternalQueue(_ url: URL) {
        UIApplication.shared.open(url)
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    func showTicket(ticketID: UUID) {
        (viewController?.tabBarController as? MainTabBarController)?.showTicket(ticketID)
    }
}
