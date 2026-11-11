import Foundation
import MapKit

// Business logic: finds venues, from the demo list plus real places discovered through Apple Maps.
final class ExploreInteractor: ExploreInteractorProtocol {

    private let repository: VenueProviding
    private let placeSearch: PlaceSearching
    private let suggester: PlaceSuggesting
    private let simulator: QueueSimulating

    init(repository: VenueProviding = VenueRepository.shared,
         placeSearch: PlaceSearching = PlaceSearchService(),
         suggester: PlaceSuggesting = PlaceSuggestionService(),
         simulator: QueueSimulating = QueueSimulator.shared) {
        self.repository = repository
        self.placeSearch = placeSearch
        self.suggester = suggester
        self.simulator = simulator
    }

    func listings(matching query: String, category: VenueCategory?) -> [VenueListing] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return repository.venues
            .filter { category == nil || $0.category == category }
            .filter { trimmed.isEmpty
                || $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.address.localizedCaseInsensitiveContains(trimmed) }
            .map { VenueListing(venue: $0, snapshot: simulator.snapshot(for: $0.id)) }
    }

    // Only venues inside the visible map area (plus a margin), so old searches don't clutter the map.
    func listings(matching query: String, category: VenueCategory?, in region: MKCoordinateRegion) -> [VenueListing] {
        listings(matching: query, category: category).filter { Self.region(region, contains: $0.venue, margin: 1.1) }
    }

    private static func region(_ region: MKCoordinateRegion, contains venue: Venue, margin: Double) -> Bool {
        abs(venue.latitude - region.center.latitude) <= region.span.latitudeDelta / 2 * margin
            && abs(venue.longitude - region.center.longitude) <= region.span.longitudeDelta / 2 * margin
    }

    // Searches every known venue (not just the ones on screen). Closest matches to the map centre come first.
    func localSuggestions(matching query: String, near center: CLLocationCoordinate2D) -> [PlaceSuggestion] {
        let here = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return repository.venues
            .compactMap { venue -> (Venue, Int, CLLocationDistance)? in
                guard let rank = SearchText.rank(query: query, name: venue.name, address: venue.address) else { return nil }
                return (venue, rank, here.distance(from: CLLocation(latitude: venue.latitude, longitude: venue.longitude)))
            }
            .sorted { ($0.1, $0.2) < ($1.1, $1.2) }
            .prefix(6)
            .map { PlaceSuggestion(id: $0.0.id, title: $0.0.name, subtitle: $0.0.address, category: $0.0.category,
                                   source: .local, venue: $0.0, googlePlaceID: nil) }
    }

    func remoteSuggestions(for query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion] {
        await suggester.suggestions(for: query, near: center)
    }

    // Turns a result into a saved venue, so it has a pin and a details page.
    func resolve(_ suggestion: PlaceSuggestion) async -> Venue? {
        if suggestion.source == .local, let venue = suggestion.venue { return venue }
        guard let venue = await suggester.resolve(suggestion) else { return nil }
        return repository.resolve(venue)
    }

    func listing(id: String) -> VenueListing? {
        guard let venue = repository.venue(id: id) else { return nil }
        return VenueListing(venue: venue, snapshot: simulator.snapshot(for: id))
    }

    // onProgress runs each time a batch of new places has been saved.
    @MainActor
    func discoverPlaces(in region: MKCoordinateRegion, onProgress: () -> Void) async throws {
        try await placeSearch.searchFoodPlaces(in: region) { [repository] found in
            if repository.add(found) > 0 { onProgress() }
        }
    }
}
