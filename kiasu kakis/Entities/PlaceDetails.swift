import Foundation

// Extra information about a real place, fetched from Google Places.
struct PlaceDetails: Codable, Equatable {
    var rating: Double?
    var ratingCount: Int?
    // 0 (free) to 4 (very expensive).
    var priceLevel: Int?
    var openNow: Bool?
    // One line per day, Monday first, e.g. "Monday: 11:00 AM – 9:00 PM".
    var weekdayHours: [String] = []
    var photoName: String?
    var photoAuthor: String?
    var fetchedAt: Date

    // True when Google had nothing useful for this place.
    var isEmpty: Bool {
        rating == nil && priceLevel == nil && openNow == nil && weekdayHours.isEmpty && photoName == nil
    }
}
