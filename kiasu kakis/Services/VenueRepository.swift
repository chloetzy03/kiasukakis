import Foundation
import CoreLocation

protocol VenueProviding: AnyObject {
    var venues: [Venue] { get }
    func venue(id: String) -> Venue?
    @discardableResult func add(_ venues: [Venue]) -> Int
    // Returns the stored venue: an existing one if this is the same place, otherwise the new one after saving it.
    func resolve(_ venue: Venue) -> Venue
}

// One place to look up venues: the curated queue places plus real places found through Apple Maps and Google.
// Discovered places are saved to disk so saved venues still resolve after relaunch.
// A share of the discovered places is given a simulated queue (see SimulatedQueueCatalog).
final class VenueRepository: VenueProviding {

    static let shared = VenueRepository()

    // The earlier version also saved malls and supermarkets. A new file name starts clean, so those disappear.
    private static let filename = "discovered_venues_v2.json"
    private static let oldFilename = "discovered_venues.json"
    private let store: LocalStore
    private let queues: QueueProfileProviding
    private let externalQueues: ExternalQueueProviding
    private let curated: [Venue]
    private var discovered: [Venue] {
        didSet { store.save(discovered, to: Self.filename) }
    }

    init(store: LocalStore = LocalStore(), queues: QueueProfileProviding = SimulatedQueueCatalog(),
         externalQueues: ExternalQueueProviding = ExternalQueueDirectory()) {
        self.store = store
        self.queues = queues
        self.externalQueues = externalQueues
        self.curated = DemoVenueData.venues.map { Self.withQueueBehaviour($0, using: queues, external: externalQueues) }
        store.delete(Self.oldFilename)
        let saved = Self.unique(store.load([Venue].self, from: Self.filename) ?? [])
        self.discovered = saved.map { Self.withQueueBehaviour($0, using: queues, external: externalQueues) }
    }

    var venues: [Venue] { curated + discovered }

    func venue(id: String) -> Venue? { venues.first { $0.id == id } }

    func resolve(_ candidate: Venue) -> Venue {
        if let existing = venue(id: candidate.id) ?? sameSpot(as: candidate) { return existing }
        add([candidate])
        return venue(id: candidate.id) ?? candidate
    }

    // Decides how a venue's queue works. Venues with their own system link out. Otherwise the catalog may give
    // the venue a simulated queue, which is joinable (venue system) or community-reported (like hawker stalls).
    private static func withQueueBehaviour(_ venue: Venue, using queues: QueueProfileProviding,
                                           external: ExternalQueueProviding) -> Venue {
        var result = venue
        if let url = external.queueURL(for: venue) {
            result.externalQueueURL = url
            result.queueSupport = .external
            result.isDemo = queues.profile(for: venue) != nil || venue.isDemo
            return result
        }
        guard let profile = queues.profile(for: venue) else { return venue }
        result.isDemo = true
        result.queueSupport = profile.supportsRemoteJoin ? .native : .crowd
        return result
    }

    // Apple Maps and Google can describe the same place with different ids, and our curated queue places
    // are also found by the map search, so match by name and distance.
    private func sameSpot(as candidate: Venue) -> Venue? {
        let spot = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
        let name = SearchText.normalized(candidate.name)
        return venues.first { other in
            let otherName = SearchText.normalized(other.name)
            return (otherName.contains(name) || name.contains(otherName))
                && CLLocation(latitude: other.latitude, longitude: other.longitude).distance(from: spot) < 80
        }
    }

    // Returns how many were new.
    @discardableResult
    func add(_ newVenues: [Venue]) -> Int {
        var known = Set(venues.map(\.id))
        let fresh = newVenues
            .filter { known.insert($0.id).inserted && sameSpot(as: $0) == nil }
            .map { Self.withQueueBehaviour($0, using: queues, external: externalQueues) }
        if !fresh.isEmpty { discovered.append(contentsOf: fresh) }
        return fresh.count
    }

    // Earlier versions could save two places with the same id, which crashed the map on launch.
    private static func unique(_ venues: [Venue]) -> [Venue] {
        var seen = Set(DemoVenueData.venues.map(\.id))
        return venues.filter { seen.insert($0.id).inserted }
    }
}
