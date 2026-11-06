import Foundation

final class MyQueuesInteractor: MyQueuesInteractorProtocol {

    private let service: QueueServicing

    init(service: QueueServicing = QueueService.shared) {
        self.service = service
    }

    var tickets: [QueueTicket] { service.tickets }
}
