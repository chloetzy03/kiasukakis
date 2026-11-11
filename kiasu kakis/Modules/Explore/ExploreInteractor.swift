import Foundation
import MapKit

// Business logic: finds venues, from the demo list plus real places discovered through Apple Maps.
final class ExploreInteractor: ExploreInteractorProtocol {

    private let repository: VenueProviding
    private let placeSearch: PlaceSearching

    init(repository: VenueProviding = VenueRepository.shared,
         placeSearch: PlaceSearching = PlaceSearchService()) {
        self.repository = repository
        self.placeSearch = placeSearch
    }

    func listings(matching query: String, category: VenueCategory?) -> [VenueListing] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return repository.venues
            .filter { category == nil || $0.category == category }
            .filter { trimmed.isEmpty
                || $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.address.localizedCaseInsensitiveContains(trimmed) }
            .map { VenueListing(venue: $0, snapshot: DemoVenueData.snapshot(for: $0.id)) }
    }

    // Only venues inside the visible map area (plus a margin), so old searches don't clutter the map.
    func listings(matching query: String, category: VenueCategory?, in region: MKCoordinateRegion) -> [VenueListing] {
        listings(matching: query, category: category).filter { Self.region(region, contains: $0.venue, margin: 1.1) }
    }

    private static func region(_ region: MKCoordinateRegion, contains venue: Venue, margin: Double) -> Bool {
        abs(venue.latitude - region.center.latitude) <= region.span.latitudeDelta / 2 * margin
            && abs(venue.longitude - region.center.longitude) <= region.span.longitudeDelta / 2 * margin
    }

    func listing(id: String) -> VenueListing? {
        guard let venue = repository.venue(id: id) else { return nil }
        return VenueListing(venue: venue, snapshot: DemoVenueData.snapshot(for: id))
    }

    // Returns how many new places were added.
    func discoverPlaces(in region: MKCoordinateRegion) async throws -> Int {
        let found = try await placeSearch.searchFoodPlaces(in: region)
        return repository.add(found)
    }
}
