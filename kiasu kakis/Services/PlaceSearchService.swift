import MapKit

protocol PlaceSearching: AnyObject {
    func searchFoodPlaces(in region: MKCoordinateRegion) async throws -> [Venue]
}

// Finds real food places inside the visible map area using Apple's MKLocalSearch.
final class PlaceSearchService: PlaceSearching {

    private static let maxResultsPerQuery = 15
    private static let queries = ["restaurant", "cafe", "food court"]

    // One search only returns a few places, so we run several searches and merge the results.
    func searchFoodPlaces(in region: MKCoordinateRegion) async throws -> [Venue] {
        try await withThrowingTaskGroup(of: [Venue].self) { group in
            for query in Self.queries {
                group.addTask { try await Self.search(query, in: region) }
            }
            var all: [Venue] = []
            for try await venues in group { all += venues }
            var seen = Set<String>()
            return all.filter { seen.insert($0.id).inserted }
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
