import MapKit

protocol PlaceSearching: AnyObject {
    // Calls onBatch as soon as each search finishes, so pins can appear one search at a time.
    @MainActor func searchFoodPlaces(in region: MKCoordinateRegion, onBatch: ([Venue]) -> Void) async throws
}

// Finds real food places inside the visible map area using Apple's MKLocalSearch.
final class PlaceSearchService: PlaceSearching {

    private static let maxResultsPerQuery = 15
    private static let queries = ["restaurant", "cafe", "food court"]

    // One search only returns a few places, so we run several searches at the same time.
    @MainActor
    func searchFoodPlaces(in region: MKCoordinateRegion, onBatch: ([Venue]) -> Void) async throws {
        try await withThrowingTaskGroup(of: [Venue].self) { group in
            for query in Self.queries {
                group.addTask { try await Self.search(query, in: region) }
            }
            for try await venues in group { onBatch(venues) }
        }
    }

    private static func search(_ query: String, in region: MKCoordinateRegion) async throws -> [Venue] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery, .foodMarket])
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.prefix(maxResultsPerQuery).compactMap(makeVenue)
    }

    private static func makeVenue(from item: MKMapItem) -> Venue? {
        guard let name = item.name else { return nil }
        let coordinate = item.placemark.coordinate
        return Venue(id: String(format: "mk-%.5f-%.5f", coordinate.latitude, coordinate.longitude),
                     name: name,
                     address: item.placemark.title ?? "Singapore",
                     category: category(for: item.pointOfInterestCategory),
                     latitude: coordinate.latitude,
                     longitude: coordinate.longitude,
                     queueSupport: .unsupported,
                     isDemo: false)
    }

    private static func category(for poi: MKPointOfInterestCategory?) -> VenueCategory {
        if poi == .cafe { return .cafe }
        if poi == .bakery { return .dessert }
        if poi == .foodMarket { return .hawker }
        return .restaurant
    }
}
