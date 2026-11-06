import MapKit

protocol PlaceSearching: AnyObject {
    func searchFoodPlaces(in region: MKCoordinateRegion) async throws -> [Venue]
}

// Finds real food places inside the visible map area using Apple's MKLocalSearch.
final class PlaceSearchService: PlaceSearching {

    private static let maxResults = 15

    func searchFoodPlaces(in region: MKCoordinateRegion) async throws -> [Venue] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "food"
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery, .foodMarket])

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.prefix(Self.maxResults).compactMap(Self.makeVenue)
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
