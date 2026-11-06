import Foundation

// All venues and waiting times are fictional demonstration data.
enum DemoVenueData {

    static let venues: [Venue] = [
        Venue(id: "v1", name: "Hainan Delight Chicken Rice", address: "Lotus Food Centre, Singapore",
              category: .hawker, latitude: 1.2804, longitude: 103.8441, queueSupport: .unsupported),
        Venue(id: "v2", name: "Golden Bowl Noodle House", address: "1 Orchard Lane, Singapore",
              category: .restaurant, latitude: 1.3009, longitude: 103.8396, queueSupport: .demoSupported),
        Venue(id: "v3", name: "Corner Brew Café", address: "2 Palm Road, Singapore",
              category: .cafe, latitude: 1.2966, longitude: 103.8520, queueSupport: .unsupported),
        Venue(id: "v4", name: "Sweet Lane Dessert Bar", address: "3 Rose Lane, Singapore",
              category: .dessert, latitude: 1.3048, longitude: 103.8318, queueSupport: .demoSupported),
        Venue(id: "v5", name: "Smoky Skewers Satay", address: "Lotus Food Centre, Singapore",
              category: .hawker, latitude: 1.2816, longitude: 103.8500, queueSupport: .closed),
        Venue(id: "v6", name: "Lantern Gardens Entrance", address: "4 Harbour Avenue, Singapore",
              category: .attraction, latitude: 1.2816, longitude: 103.8636, queueSupport: .demoSupported)
    ]

    static func snapshot(for venueID: String, now: Date = Date()) -> QueueSnapshot {
        switch venueID {
        case "v1": return QueueSnapshot(venueID: venueID, waitMinutes: 40, source: .communityObservation, timestamp: now.addingTimeInterval(-600))
        case "v2": return QueueSnapshot(venueID: venueID, waitMinutes: 15, source: .demoSimulation, timestamp: now.addingTimeInterval(-120))
        case "v4": return QueueSnapshot(venueID: venueID, waitMinutes: 8, source: .demoSimulation, timestamp: now.addingTimeInterval(-300))
        case "v6": return QueueSnapshot(venueID: venueID, waitMinutes: 25, source: .demoSimulation, timestamp: now.addingTimeInterval(-60))
        default: return QueueSnapshot(venueID: venueID, waitMinutes: nil, source: .communityObservation, timestamp: .distantPast)
        }
    }
}
