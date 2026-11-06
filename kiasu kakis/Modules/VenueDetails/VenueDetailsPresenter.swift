import UIKit

final class VenueDetailsPresenter: VenueDetailsPresenterProtocol {

    weak var view: VenueDetailsViewProtocol?
    private let interactor: VenueDetailsInteractorProtocol
    private let router: VenueDetailsRouterProtocol
    private var travelAction: TravelAction?

    private enum TravelAction { case allowLocation, openSettings }

    init(interactor: VenueDetailsInteractorProtocol, router: VenueDetailsRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        render()
        loadTravel(requestPermission: false)
    }
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

    func didTapTravelAction() {
        switch travelAction {
        case .allowLocation: loadTravel(requestPermission: true)
        case .openSettings: router.openSettings()
        case nil: break
        }
    }

    private func loadTravel(requestPermission: Bool) {
        travelAction = nil
        view?.showTravel(TravelViewModel(summary: "Calculating travel time…", hint: nil, actionTitle: nil, isLoading: true))
        Task { [weak self] in
            guard let self else { return }
            let result = await interactor.loadTravel(requestPermission: requestPermission)
            view?.showTravel(makeTravelViewModel(result))
        }
    }

    private func makeTravelViewModel(_ result: TravelResult) -> TravelViewModel {
        switch result {
        case .ready(let times):
            travelAction = nil
            var parts: [String] = []
            if let walking = times.walkingMinutes { parts.append("\(walking) min walk") }
            if let driving = times.drivingMinutes { parts.append("\(driving) min drive") }
            return TravelViewModel(summary: parts.joined(separator: " · "),
                                   hint: travelHint(fastest: times.fastestMinutes),
                                   actionTitle: nil, isLoading: false)
        case .needsPermission:
            travelAction = .allowLocation
            return TravelViewModel(summary: "Allow location to see how long it takes to get here.",
                                   hint: nil, actionTitle: "Allow location", isLoading: false)
        case .denied:
            travelAction = .openSettings
            return TravelViewModel(summary: "Location is off, so travel time isn't available.",
                                   hint: nil, actionTitle: "Open Settings", isLoading: false)
        case .unavailable:
            travelAction = nil
            return TravelViewModel(summary: "Travel time isn't available right now.",
                                   hint: nil, actionTitle: nil, isLoading: false)
        }
    }

    // Compares the trip with the queue so the user can decide when to leave.
    private func travelHint(fastest: Int?) -> String? {
        guard let travel = fastest, let wait = interactor.snapshot.waitMinutes else {
            return "No recent queue data to compare with."
        }
        return travel >= wait
            ? "The queue (about \(wait) min) may clear before you arrive, so leave soon."
            : "The queue (about \(wait) min) is longer than your trip, so you have time before leaving."
    }

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
        case .unsupported where !venue.isDemo:
            status = ("info.circle", "No queue information",
                      "This is a real place from Apple Maps. Kiasu Kakis has no queue data for it, and remote joining isn't available.",
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
            disclaimer: venue.isDemo ? "Demo data. All venues, wait times and tickets are fictional." : "Place details from Apple Maps. Queue data isn't available.",
            isSaved: interactor.isSaved))
    }
}
