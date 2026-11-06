import UIKit

final class VenueDetailsPresenter: VenueDetailsPresenterProtocol {

    weak var view: VenueDetailsViewProtocol?
    private let interactor: VenueDetailsInteractorProtocol
    private let router: VenueDetailsRouterProtocol

    init(interactor: VenueDetailsInteractorProtocol, router: VenueDetailsRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() { render() }
    func viewWillAppear() { render() }

    func didTapSave() {
        interactor.toggleSaved()
        render()
    }

    func didTapJoin() {
        if let ticket = interactor.activeTicket {
            router.showTicket(ticketID: ticket.id)
            return
        }
        guard interactor.venue.queueSupport == .demoSupported else { return }
        router.showJoinQueue(for: interactor.venue)
    }

    func didTapOpenInMaps() { router.openInMaps(interactor.venue) }

    private func render() {
        let venue = interactor.venue
        let snapshot = interactor.snapshot
        let hasData = snapshot.waitMinutes != nil

        let status: (symbol: String, title: String, message: String, color: UIColor)
        switch venue.queueSupport {
        case .demoSupported:
            status = ("checkmark.circle.fill", "Demo virtual queue available",
                      "This venue supports a simulated virtual queue for testing. No real venue is involved.",
                      Theme.waitShort)
        case .closed:
            status = ("moon.zzz.fill", "Queue closed",
                      "This venue isn't accepting new tickets right now.",
                      .systemGray)
        case .unsupported:
            status = ("nosign", "Remote queue not supported",
                      "This venue doesn't offer remote joining. You'd need to queue on site.",
                      .systemGray)
        }

        let updated: String
        if hasData {
            let relative = RelativeDateTimeFormatter().localizedString(for: snapshot.timestamp, relativeTo: Date())
            updated = "Updated \(relative)"
        } else {
            updated = "No recent queue information. This is not a 0-minute wait."
        }

        view?.show(VenueDetailsViewModel(
            name: venue.name,
            categoryText: venue.category.rawValue,
            address: venue.address,
            waitText: hasData ? "\(snapshot.waitMinutes ?? 0) min" : "No recent reports",
            waitColor: Theme.waitColor(forMinutes: snapshot.waitMinutes),
            sourceText: hasData ? "Source: \(snapshot.source.rawValue)" : "Source: none available",
            updatedText: updated,
            statusSymbol: status.symbol,
            statusTitle: status.title,
            statusMessage: status.message,
            statusColor: status.color,
            canJoin: venue.queueSupport == .demoSupported,
            hasActiveTicket: interactor.activeTicket != nil,
            isSaved: interactor.isSaved))
    }
}
