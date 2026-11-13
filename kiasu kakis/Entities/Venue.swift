import Foundation

enum VenueCategory: String, Codable, CaseIterable {
    case hawker = "Hawker"
    case restaurant = "Restaurant"
    case cafe = "Café"
    case dessert = "Dessert"
    case bar = "Bar"
    case attraction = "Attraction"
}

// How a venue's queue can be used from the app.
enum QueueSupport: String, Codable {
    // Joined inside Kiasu Kakis. The raw value is the old name, so data saved by earlier versions still loads.
    case native = "demoSupported"
    // The venue runs its own queue system, so we link out to it.
    case external
    // Hawker stalls and similar: the wait is reported by people in line, and you queue on site.
    case crowd
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
    var queueSupport: QueueSupport
    // false for real places found through Apple Maps search.
    var isDemo: Bool = true
    // Where to join when the venue runs its own queue (see QueueSupport.external).
    var externalQueueURL: URL?
}
