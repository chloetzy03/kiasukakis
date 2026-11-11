import Foundation
import CoreLocation

protocol PlaceDetailsProviding: AnyObject {
    var isConfigured: Bool { get }
    func details(for venue: Venue) async -> PlaceDetails?
    func photoData(for details: PlaceDetails, venueID: String) async -> Data?
}

// Asks the Google Places API (New) for ratings, opening hours and a photo of a real place.
// Results are cached on disk for a day, because every request costs a little.
final class GooglePlacesService: PlaceDetailsProviding {

    static let shared = GooglePlacesService()

    private static let cacheFilename = "place_details.json"
    private static let cacheLifetime: TimeInterval = 24 * 60 * 60
    private static let maxMatchDistance: CLLocationDistance = 250

    private let apiKey: String?
    private let session: URLSession
    private let store: LocalStore
    private let photoDirectory: URL
    private var cache: [String: PlaceDetails]

    init(apiKey: String? = GooglePlacesService.keyFromBundle(),
         session: URLSession = .shared,
         store: LocalStore = LocalStore(),
         photoDirectory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("place_photos")) {
        self.apiKey = apiKey
        self.session = session
        self.store = store
        self.photoDirectory = photoDirectory
        self.cache = store.load([String: PlaceDetails].self, from: Self.cacheFilename) ?? [:]
    }

    var isConfigured: Bool { apiKey != nil }

    // The key lives in Secrets.xcconfig (not in git) and reaches the app through Info.plist.
    static func keyFromBundle(_ bundle: Bundle = .main) -> String? {
        guard let key = bundle.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String else { return nil }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaceholder = trimmed.isEmpty || trimmed.hasPrefix("$(") || trimmed == "PASTE_YOUR_KEY_HERE"
        return isPlaceholder ? nil : trimmed
    }

    // MARK: - Details

    func details(for venue: Venue) async -> PlaceDetails? {
        // Demo venues are made up, so Google has nothing for them.
        guard !venue.isDemo, let apiKey else { return nil }
        if let cached = cache[venue.id], Date().timeIntervalSince(cached.fetchedAt) < Self.cacheLifetime {
            return cached.isEmpty ? nil : cached
        }
        do {
            let fresh = try await fetch(venue, apiKey: apiKey)
            cache[venue.id] = fresh
            store.save(cache, to: Self.cacheFilename)
            return fresh.isEmpty ? nil : fresh
        } catch {
            // Offline or Google error: an old answer is better than nothing.
            return cache[venue.id].flatMap { $0.isEmpty ? nil : $0 }
        }
    }

    private func fetch(_ venue: Venue, apiKey: String) async throws -> PlaceDetails {
        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/places:searchText")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // The field mask asks only for what the app shows, which keeps each request cheap.
        request.setValue("places.displayName,places.location,places.rating,places.userRatingCount,places.priceLevel,"
                         + "places.currentOpeningHours.openNow,places.regularOpeningHours.weekdayDescriptions,"
                         + "places.photos.name,places.photos.authorAttributions.displayName",
                         forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONEncoder().encode(SearchBody(
            textQuery: venue.name,
            maxResultCount: 5,
            locationBias: .init(circle: .init(center: .init(latitude: venue.latitude, longitude: venue.longitude),
                                              radius: 150))))

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw PlacesError.badResponse }
        let places = try JSONDecoder().decode(SearchResponse.self, from: data).places ?? []

        // Take the closest result, and only if it is really the same spot.
        let here = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
        let match = places
            .compactMap { place -> (GooglePlace, CLLocationDistance)? in
                guard let loc = place.location else { return nil }
                return (place, here.distance(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude)))
            }
            .filter { $0.1 <= Self.maxMatchDistance }
            .min { $0.1 < $1.1 }?.0

        guard let match else { return PlaceDetails(fetchedAt: Date()) }
        return PlaceDetails(rating: match.rating,
                            ratingCount: match.userRatingCount,
                            priceLevel: match.priceLevel.flatMap(Self.priceLevelNumber),
                            openNow: match.currentOpeningHours?.openNow,
                            weekdayHours: match.regularOpeningHours?.weekdayDescriptions ?? [],
                            photoName: match.photos?.first?.name,
                            photoAuthor: match.photos?.first?.authorAttributions?.first?.displayName,
                            fetchedAt: Date())
    }

    static func priceLevelNumber(_ text: String) -> Int? {
        switch text {
        case "PRICE_LEVEL_FREE": return 0
        case "PRICE_LEVEL_INEXPENSIVE": return 1
        case "PRICE_LEVEL_MODERATE": return 2
        case "PRICE_LEVEL_EXPENSIVE": return 3
        case "PRICE_LEVEL_VERY_EXPENSIVE": return 4
        default: return nil
        }
    }

    // MARK: - Photo

    func photoData(for details: PlaceDetails, venueID: String) async -> Data? {
        guard let name = details.photoName, let apiKey else { return nil }
        let file = photoDirectory.appendingPathComponent(Self.safeFilename(venueID) + ".jpg")
        if let cached = try? Data(contentsOf: file) { return cached }

        guard let url = URL(string: "https://places.googleapis.com/v1/\(name)/media?maxWidthPx=900") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              (response.mimeType ?? "").hasPrefix("image") else { return nil }
        try? FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        return data
    }

    private static func safeFilename(_ id: String) -> String {
        id.map { $0.isLetter || $0.isNumber || $0 == "-" ? String($0) : "_" }.joined()
    }

    // MARK: - JSON shapes

    private enum PlacesError: Error { case badResponse }

    private struct SearchBody: Encodable {
        struct LatLng: Encodable { let latitude: Double; let longitude: Double }
        struct Circle: Encodable { let center: LatLng; let radius: Double }
        struct Bias: Encodable { let circle: Circle }
        let textQuery: String
        let maxResultCount: Int
        let locationBias: Bias
    }

    private struct SearchResponse: Decodable { let places: [GooglePlace]? }

    private struct GooglePlace: Decodable {
        struct Location: Decodable { let latitude: Double; let longitude: Double }
        struct OpeningNow: Decodable { let openNow: Bool? }
        struct RegularHours: Decodable { let weekdayDescriptions: [String]? }
        struct Photo: Decodable {
            struct Author: Decodable { let displayName: String? }
            let name: String
            let authorAttributions: [Author]?
        }
        let location: Location?
        let rating: Double?
        let userRatingCount: Int?
        let priceLevel: String?
        let currentOpeningHours: OpeningNow?
        let regularOpeningHours: RegularHours?
        let photos: [Photo]?
    }
}
