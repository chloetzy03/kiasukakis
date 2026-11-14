import Foundation

// Where a venue's table types come from. The rest of the app only asks this, so a server (or the venue's own
// staff screen) can replace the bundled file later without touching any screen.
protocol VenueConfigProviding {
    func config(for venue: Venue) -> VenueQueueConfig
}

// The shape of venue_configs.json: one default for every place, plus overrides by venue id.
struct VenueConfigRegistry: Codable, Equatable {
    let `default`: VenueQueueConfig
    let venues: [String: VenueQueueConfig]

    static func parse(_ data: Data) -> VenueConfigRegistry? {
        guard let registry = try? JSONDecoder().decode(VenueConfigRegistry.self, from: data), registry.isValid else { return nil }
        return registry
    }

    // A broken file must never leave a venue with no tables, so every list needs at least one sensible type.
    var isValid: Bool {
        ([`default`] + venues.values).allSatisfy { config in
            !config.tableTypes.isEmpty && config.tableTypes.allSatisfy { $0.minParty >= 1 && $0.maxParty >= $0.minParty && $0.waitFactor > 0 }
        }
    }

    // Used only if the file is missing or invalid.
    static let fallback = VenueConfigRegistry(
        default: VenueQueueConfig(tableTypes: [
            TableType(id: "small", name: "1–2 people", minParty: 1, maxParty: 2, waitFactor: 0.8),
            TableType(id: "medium", name: "3–4 people", minParty: 3, maxParty: 4, waitFactor: 1.0),
            TableType(id: "large", name: "5–8 people", minParty: 5, maxParty: 8, waitFactor: 1.4)
        ]),
        venues: [:])
}

struct BundledVenueConfigs: VenueConfigProviding {

    static let shared = BundledVenueConfigs()

    private let registry: VenueConfigRegistry

    init(registry: VenueConfigRegistry) { self.registry = registry }

    init(bundle: Bundle = .main) {
        let data = bundle.url(forResource: "venue_configs", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        self.registry = data.flatMap { VenueConfigRegistry.parse($0) } ?? .fallback
    }

    func config(for venue: Venue) -> VenueQueueConfig {
        registry.venues[venue.id] ?? registry.default
    }
}
