import Foundation

// Business logic: finds venues. Today it reads demo data; later it could call a server.
final class ExploreInteractor: ExploreInteractorProtocol {

    func listings(matching query: String, category: VenueCategory?) -> [VenueListing] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return DemoVenueData.venues
            .filter { category == nil || $0.category == category }
            .filter { trimmed.isEmpty
                || $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.address.localizedCaseInsensitiveContains(trimmed) }
            .map { VenueListing(venue: $0, snapshot: DemoVenueData.snapshot(for: $0.id)) }
    }

    func listing(id: String) -> VenueListing? {
        guard let venue = DemoVenueData.venues.first(where: { $0.id == id }) else { return nil }
        return VenueListing(venue: venue, snapshot: DemoVenueData.snapshot(for: id))
    }
}
