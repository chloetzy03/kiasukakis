import Foundation

// Real Singapore food places that are known for queues. The places are real, but their queues in this app
// are simulated for the demo (see QueueSimulator). Locations come from Apple Maps.
enum DemoVenueData {

    static let curatedIDs: Set<String> = Set(venues.map(\.id))

    static let venues: [Venue] = [
        Venue(id: "v1", name: "Tian Tian Hainanese Chicken Rice", address: "Maxwell Food Centre, 1 Kadayanallur St",
              category: .hawker, latitude: 1.28035, longitude: 103.84474, queueSupport: .unsupported),
        Venue(id: "v2", name: "Hawker Chan", address: "Chinatown Complex, 335 Smith St",
              category: .hawker, latitude: 1.28260, longitude: 103.84308, queueSupport: .unsupported),
        Venue(id: "v3", name: "Tai Hwa Pork Noodle", address: "466 Crawford Lane",
              category: .hawker, latitude: 1.30509, longitude: 103.86260, queueSupport: .unsupported),
        Venue(id: "v4", name: "Song Fa Bak Kut Teh", address: "11 New Bridge Rd",
              category: .restaurant, latitude: 1.28898, longitude: 103.84773, queueSupport: .demoSupported),
        Venue(id: "v5", name: "Jumbo Seafood", address: "Riverside Point, 30 Merchant Rd",
              category: .restaurant, latitude: 1.28885, longitude: 103.84466, queueSupport: .demoSupported),
        Venue(id: "v6", name: "Din Tai Fung", address: "Paragon, 290 Orchard Rd",
              category: .restaurant, latitude: 1.30358, longitude: 103.83566, queueSupport: .demoSupported),
        Venue(id: "v7", name: "Mei Heong Yuen Dessert", address: "63 Temple St",
              category: .dessert, latitude: 1.28322, longitude: 103.84330, queueSupport: .demoSupported),
        Venue(id: "v8", name: "Tiong Bahru Bakery", address: "56 Eng Hoon St",
              category: .cafe, latitude: 1.28446, longitude: 103.83363, queueSupport: .demoSupported),
        Venue(id: "v9", name: "Ya Kun Kaya Toast", address: "Far East Square, 18 China St",
              category: .cafe, latitude: 1.28370, longitude: 103.84790, queueSupport: .demoSupported),
        Venue(id: "v10", name: "KOI Thé", address: "ION Orchard, 2 Orchard Turn",
              category: .dessert, latitude: 1.30421, longitude: 103.83187, queueSupport: .demoSupported),
        Venue(id: "v11", name: "Birds of Paradise Gelato", address: "263 Beach Rd",
              category: .dessert, latitude: 1.30062, longitude: 103.85996, queueSupport: .demoSupported),
        // No queue data on purpose, to show the "no recent reports" state.
        Venue(id: "v12", name: "Ah Chiang's Porridge", address: "65 Tiong Poh Rd",
              category: .restaurant, latitude: 1.28313, longitude: 103.83310, queueSupport: .unsupported)
    ]
}
