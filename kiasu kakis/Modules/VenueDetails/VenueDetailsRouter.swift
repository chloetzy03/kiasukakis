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
        // Replaced by the real Join Queue module in Milestone 4.
        let alert = UIAlertController(title: "Join demo queue",
                                      message: "Joining a demo queue arrives in Milestone 4.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController?.present(alert, animated: true)
    }
}
