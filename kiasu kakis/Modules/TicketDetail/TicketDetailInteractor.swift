import Foundation

final class TicketDetailInteractor: TicketDetailInteractorProtocol {

    private let ticketID: UUID
    private let service: QueueServicing

    init(ticketID: UUID, service: QueueServicing = QueueService.shared) {
        self.ticketID = ticketID
        self.service = service
    }

    var ticket: QueueTicket? { service.ticket(id: ticketID) }
    func advance() { service.advance(ticketID: ticketID) }
    func cancel() { service.cancel(ticketID: ticketID) }
}
