import Foundation

protocol VenueProviding: AnyObject {
    var venues: [Venue] { get }
    func venue(id: String) -> Venue?
    @discardableResult func add(_ venues: [Venue]) -> Int
}

// One place to look up venues: the fictional demo ones plus real places found through Apple Maps.
// Discovered places are saved to disk so saved venues still resolve after relaunch.
final class VenueRepository: VenueProviding {

    static let shared = VenueRepository()

    private static let filename = "discovered_venues.json"
    private let store: LocalStore
    private var discovered: [Venue] {
        didSet { store.save(discovered, to: Self.filename) }
    }

    init(store: LocalStore = LocalStore()) {
        self.store = store
        self.discovered = Self.unique(store.load([Venue].self, from: Self.filename) ?? [])
    }

    var venues: [Venue] { DemoVenueData.venues + discovered }

    func venue(id: String) -> Venue? { venues.first { $0.id == id } }

    // Returns how many were new.
    func add(_ newVenues: [Venue]) -> Int {
        var known = Set(venues.map(\.id))
        let fresh = newVenues.filter { known.insert($0.id).inserted }
        if !fresh.isEmpty { discovered.append(contentsOf: fresh) }
        return fresh.count
    }

    // Earlier versions could save two places with the same id, which crashed the map on launch.
    private static func unique(_ venues: [Venue]) -> [Venue] {
        var seen = Set(DemoVenueData.venues.map(\.id))
        return venues.filter { seen.insert($0.id).inserted }
    }
}
