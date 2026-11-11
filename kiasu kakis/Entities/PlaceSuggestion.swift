import Foundation

// One row in the search results list.
struct PlaceSuggestion: Equatable {
    enum Source: Equatable { case local, google, apple }

    let id: String
    let title: String
    let subtitle: String
    let category: VenueCategory?
    let source: Source
    // Known right away for local and Apple Maps results. Google results need a second request to get the location.
    var venue: Venue?
    var googlePlaceID: String?
}
