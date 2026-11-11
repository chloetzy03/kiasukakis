import Foundation

// All venues are fictional demonstration data. Their waiting times come from QueueSimulator.
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
}
