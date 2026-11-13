import Foundation

// How one venue's simulated queue behaves: its usual wait, how far it can drift, and where the number comes from.
struct QueueProfile: Equatable {
    let base: Double
    let range: ClosedRange<Double>
    let source: QueueDataSource

    // Only simulated "venue systems" accept remote joining. Community reports (like hawker stalls) do not.
    var supportsRemoteJoin: Bool { source == .demoSimulation }
}

// Decides which venues have a queue. A real data source can implement this too, and the rest of the app
// would not change: the simulator only asks "does this venue have a queue, and how does it behave?".
protocol QueueProfileProviding {
    func profile(for venue: Venue) -> QueueProfile?
}

// Gives a queue to the curated places and to a fixed share of every other place.
// The choice depends only on the venue's id, so the same place gets the same answer every time, on every launch.
struct SimulatedQueueCatalog: QueueProfileProviding {

    // The curated places (see DemoVenueData). Hawker stalls are community reports because they have no remote queue.
    static let curated: [String: QueueProfile] = [
        "v1": QueueProfile(base: 35, range: 20...55, source: .communityObservation),   // Tian Tian
        "v2": QueueProfile(base: 30, range: 18...50, source: .communityObservation),   // Hawker Chan
        "v3": QueueProfile(base: 45, range: 30...70, source: .communityObservation),   // Tai Hwa
        "v4": QueueProfile(base: 15, range: 6...28, source: .demoSimulation),          // Song Fa
        "v5": QueueProfile(base: 25, range: 12...45, source: .demoSimulation),         // Jumbo
        "v6": QueueProfile(base: 30, range: 15...50, source: .demoSimulation),         // Din Tai Fung
        "v7": QueueProfile(base: 12, range: 4...22, source: .demoSimulation),          // Mei Heong Yuen
        "v8": QueueProfile(base: 10, range: 3...20, source: .demoSimulation),          // Tiong Bahru Bakery
        "v9": QueueProfile(base: 8, range: 3...16, source: .demoSimulation),           // Ya Kun
        "v10": QueueProfile(base: 15, range: 6...30, source: .demoSimulation),         // KOI
        "v11": QueueProfile(base: 14, range: 5...28, source: .demoSimulation)          // Birds of Paradise
    ]

    // Usual wait by type of place, in minutes.
    private static func usualWait(for category: VenueCategory) -> ClosedRange<Double> {
        switch category {
        case .hawker: return 20...45
        case .restaurant: return 10...35
        case .cafe: return 5...20
        case .dessert: return 8...25
        case .bar: return 10...35
        case .attraction: return 10...30
        }
    }

    // The share of other places that get a queue. Lower means fewer pins on the map.
    let share: Double

    init(share: Double = 0.25) {
        self.share = share
    }

    func profile(for venue: Venue) -> QueueProfile? {
        if let curated = Self.curated[venue.id] { return curated }
        let hash = Self.stableHash(venue.id)
        guard Double(hash % 1000) / 1000 < share else { return nil }

        let usual = Self.usualWait(for: venue.category)
        let position = Double((hash >> 12) % 1000) / 1000
        let base = (usual.lowerBound + (usual.upperBound - usual.lowerBound) * position).rounded()
        return QueueProfile(base: base,
                            range: max(2, base * 0.45)...(base * 1.7),
                            source: venue.category == .hawker ? .communityObservation : .demoSimulation)
    }

    // Swift's own hashValue changes on every launch, so this uses a fixed algorithm (FNV-1a) instead.
    static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }
}
