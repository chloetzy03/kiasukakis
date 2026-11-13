import Foundation

// Cleans up data from earlier versions of the app, once.
// The first versions used six made-up venues (Golden Bowl Noodle House and so on). They were replaced by real
// places, but their old tickets and saved places were still on the phone, and the saved ids now point at
// different real places. This removes them so nothing fictional is left.
struct LegacyDataMigration {

    private static let doneKey = "didRemoveFictionalVenues"
    private static let fictionalNames: Set<String> = [
        "Hainan Delight Chicken Rice", "Golden Bowl Noodle House", "Corner Brew Café",
        "Sweet Lane Dessert Bar", "Smoky Skewers Satay", "Lantern Gardens Entrance"
    ]
    private static let fictionalIDs: Set<String> = ["v1", "v2", "v3", "v4", "v5", "v6"]

    private let queue: QueueServicing
    private let saved: SavedVenuesStoring
    private let defaults: UserDefaults

    init(queue: QueueServicing = QueueService.shared,
         saved: SavedVenuesStoring = SavedVenuesStore.shared,
         defaults: UserDefaults = .standard) {
        self.queue = queue
        self.saved = saved
        self.defaults = defaults
    }

    func runIfNeeded() {
        guard !defaults.bool(forKey: Self.doneKey) else { return }
        queue.deleteTickets { Self.fictionalNames.contains($0.venueName) }
        saved.remove(Self.fictionalIDs)
        defaults.set(true, forKey: Self.doneKey)
    }
}
