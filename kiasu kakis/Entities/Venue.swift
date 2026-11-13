import Foundation

enum VenueCategory: String, Codable, CaseIterable {
    case hawker = "Hawker"
    case restaurant = "Restaurant"
    case cafe = "Café"
    case dessert = "Dessert"
    case bar = "Bar"
    case attraction = "Attraction"
}

// Whether a venue offers (simulated) remote queueing.
enum QueueSupport: String, Codable {
    case demoSupported
    case closed
    case unsupported
}

struct Venue: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let category: VenueCategory
    let latitude: Double
    let longitude: Double
    let queueSupport: QueueSupport
    // false for real places found through Apple Maps search.
    var isDemo: Bool = true
}
