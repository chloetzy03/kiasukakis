import MapKit

protocol PlaceSearching: AnyObject {
    // Calls onBatch as soon as each search finishes, so pins can appear one search at a time.
    @MainActor func searchFoodPlaces(in region: MKCoordinateRegion, onBatch: ([Venue]) -> Void) async throws
}

// Finds real food places around the visible map area using Apple's points-of-interest request.
// The older text search only treats the region as a hint and keeps returning the same popular places,
// wherever the map is. This request really searches the circle around the centre.
final class PlaceSearchService: PlaceSearching {

    // One request returns at most 50 places, so food types are split across several requests.
    // Only places where a queue is plausible. Malls, shops, parks and supermarkets are left out on purpose.
    private static let categoryGroups: [[MKPointOfInterestCategory]] = [
        [.restaurant],
        [.cafe, .bakery]
    ]
    private static let metersPerDegree = 111_000.0

    @MainActor
    func searchFoodPlaces(in region: MKCoordinateRegion, onBatch: ([Venue]) -> Void) async throws {
        let radius = Self.radius(for: region)
        try await withThrowingTaskGroup(of: [Venue].self) { group in
            for categories in Self.categoryGroups {
                group.addTask { try await Self.search(categories, around: region.center, radius: radius) }
            }
            for try await venues in group { onBatch(venues) }
        }
    }

    // A circle that covers the whole rectangle on screen, kept within a sensible range.
    static func radius(for region: MKCoordinateRegion) -> CLLocationDistance {
        let latMeters = region.span.latitudeDelta * metersPerDegree
        let lonMeters = region.span.longitudeDelta * metersPerDegree * cos(region.center.latitude * .pi / 180)
        return min(max(max(latMeters, lonMeters) / 2, 300), 10_000)
    }

    private static func search(_ categories: [MKPointOfInterestCategory],
                               around center: CLLocationCoordinate2D,
                               radius: CLLocationDistance) async throws -> [Venue] {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap(makeVenue)
    }

    static func makeVenue(from item: MKMapItem) -> Venue? {
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
