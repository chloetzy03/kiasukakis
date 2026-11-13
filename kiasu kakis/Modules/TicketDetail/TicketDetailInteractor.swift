import Foundation

final class TicketDetailInteractor: TicketDetailInteractorProtocol {

    private let ticketID: UUID
    private let service: QueueServicing
    private let travel: TicketTravelUpdating

    init(ticketID: UUID, service: QueueServicing = QueueService.shared,
         travel: TicketTravelUpdating = TicketTravelUpdater()) {
        self.ticketID = ticketID
        self.service = service
        self.travel = travel
    }

    var ticket: QueueTicket? { service.ticket(id: ticketID) }
    func advance() { service.advance(ticketID: ticketID) }
    func cancel() { service.cancel(ticketID: ticketID) }
    var locationStatus: LocationAuthorization { travel.locationStatus }
    func refreshTravel(requestPermission: Bool) async { await travel.refresh(ticketID: ticketID, requestPermission: requestPermission) }
}
