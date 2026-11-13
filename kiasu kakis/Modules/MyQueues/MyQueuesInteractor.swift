import Foundation

final class MyQueuesInteractor: MyQueuesInteractorProtocol {

    private let service: QueueServicing
    private let savedStore: SavedVenuesStoring

    init(service: QueueServicing = QueueService.shared,
         savedStore: SavedVenuesStoring = SavedVenuesStore.shared) {
        self.service = service
        self.savedStore = savedStore
    }

    var tickets: [QueueTicket] { service.tickets }

    func deleteTicket(id: UUID) { service.deleteTicket(id: id) }

    func isSaved(venueID: String) -> Bool { savedStore.isSaved(venueID) }

    func toggleSaved(venueID: String) { savedStore.toggle(venueID) }
}
