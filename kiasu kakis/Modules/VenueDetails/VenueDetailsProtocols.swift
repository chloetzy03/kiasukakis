import UIKit

// Everything the screen needs, already formatted as text and colours.
struct VenueDetailsViewModel {
    let name: String
    let categoryText: String
    let address: String
    let waitText: String
    let waitColor: UIColor
    let sourceText: String
    let updatedText: String
    let statusSymbol: String
    let statusTitle: String
    let statusMessage: String
    let statusColor: UIColor
    let canJoin: Bool
    let isSaved: Bool
}

protocol VenueDetailsViewProtocol: AnyObject {
    func show(_ viewModel: VenueDetailsViewModel)
}

protocol VenueDetailsPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapSave()
    func didTapJoin()
    func didTapOpenInMaps()
}

protocol VenueDetailsInteractorProtocol: AnyObject {
    var venue: Venue { get }
    var snapshot: QueueSnapshot { get }
    var isSaved: Bool { get }
    func toggleSaved()
}

protocol VenueDetailsRouterProtocol: AnyObject {
    func openInMaps(_ venue: Venue)
    func showJoinQueue(for venue: Venue)
}
