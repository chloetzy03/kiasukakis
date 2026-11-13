import Foundation
import MapKit

protocol PlaceSuggesting: AnyObject {
    func suggestions(for query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion]
    func resolve(_ suggestion: PlaceSuggestion) async -> Venue?
}

// Suggests places while the user types. Uses Google autocomplete when the key is set,
// and falls back to Apple Maps search when it isn't, or when Google fails.
final class PlaceSuggestionService: PlaceSuggesting {

    private let apiKey: String?
    private let session: URLSession
    // Google bills one autocomplete "session" (typing, then picking a result) as a single event.
    private var sessionToken = UUID().uuidString

    private static let maxResults = 6

    init(apiKey: String? = GooglePlacesService.keyFromBundle(), session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func suggestions(for query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion] {
        if let apiKey, let google = try? await googleSuggestions(query, near: center, apiKey: apiKey), !google.isEmpty {
            return google
        }
        guard !Task.isCancelled else { return [] }
        return await appleSuggestions(query, near: center)
    }

    func resolve(_ suggestion: PlaceSuggestion) async -> Venue? {
        if let venue = suggestion.venue { return venue }
        guard let placeID = suggestion.googlePlaceID, let apiKey else { return nil }
        let token = sessionToken
        sessionToken = UUID().uuidString   // The next search is a new billing session.
        return try? await googleVenue(placeID: placeID, token: token, apiKey: apiKey)
    }

    // MARK: - Google

    private func googleSuggestions(_ query: String, near center: CLLocationCoordinate2D, apiKey: String) async throws -> [PlaceSuggestion] {
        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/places:autocomplete")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "input": query,
            "sessionToken": sessionToken,
            "includedRegionCodes": ["sg"],
            // Food places only. A search for a mall returns the restaurants inside it, and shops return nothing.
            "includedPrimaryTypes": ["restaurant", "cafe", "coffee_shop", "bar", "bakery"],
            "locationBias": ["circle": ["center": ["latitude": center.latitude, "longitude": center.longitude],
                                        "radius": 20_000]]
        ])
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
        return (decoded.suggestions ?? []).compactMap { $0.placePrediction }.prefix(Self.maxResults).map { prediction in
            let main = prediction.structuredFormat?.mainText?.text ?? prediction.text?.text ?? ""
            return PlaceSuggestion(id: "g-" + prediction.placeId,
                                   title: main,
                                   subtitle: prediction.structuredFormat?.secondaryText?.text ?? "",
                                   category: Self.category(fromTypes: prediction.types ?? []),
                                   source: .google,
                                   venue: nil,
                                   googlePlaceID: prediction.placeId)
        }
    }

    private func googleVenue(placeID: String, token: String, apiKey: String) async throws -> Venue {
        var components = URLComponents(string: "https://places.googleapis.com/v1/places/\(placeID)")!
        components.queryItems = [URLQueryItem(name: "sessionToken", value: token)]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 8
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("id,displayName,formattedAddress,location,primaryType,types", forHTTPHeaderField: "X-Goog-FieldMask")
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let place = try JSONDecoder().decode(PlaceResponse.self, from: data)
        guard let location = place.location else { throw URLError(.cannotParseResponse) }
        let types = [place.primaryType].compactMap { $0 } + (place.types ?? [])
        return Venue(id: "gp-" + placeID,
                     name: place.displayName?.text ?? "Place",
                     address: place.formattedAddress ?? "Singapore",
                     category: Self.category(fromTypes: types) ?? .restaurant,
                     latitude: location.latitude,
                     longitude: location.longitude,
                     queueSupport: .unsupported,
                     isDemo: false)
    }

    static func category(fromTypes types: [String]) -> VenueCategory? {
        for type in types {
            switch type {
            case "cafe", "coffee_shop", "tea_house": return .cafe
            case "bakery", "dessert_shop", "ice_cream_shop", "confectionery", "dessert_restaurant": return .dessert
            case "food_court": return .hawker
            case "bar", "pub", "night_club", "wine_bar", "cocktail_bar", "lounge_bar": return .bar
            case "tourist_attraction", "museum", "park", "amusement_park", "zoo", "aquarium": return .attraction
            case "restaurant", "meal_takeaway", "fast_food_restaurant": return .restaurant
            default: continue
            }
        }
        return nil
    }

    // MARK: - Apple Maps fallback

    private func appleSuggestions(_ query: String, near center: CLLocationCoordinate2D) async -> [PlaceSuggestion] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3))
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery, .nightlife, .brewery])
        guard let response = try? await MKLocalSearch(request: request).start() else { return [] }
        return response.mapItems.prefix(Self.maxResults).compactMap { item in
            guard let venue = PlaceSearchService.makeVenue(from: item) else { return nil }
            return PlaceSuggestion(id: venue.id, title: venue.name, subtitle: venue.address,
                                   category: venue.category, source: .apple, venue: venue, googlePlaceID: nil)
        }
    }

    // MARK: - JSON shapes

    private struct AutocompleteResponse: Decodable {
        struct Suggestion: Decodable { let placePrediction: Prediction? }
        struct Prediction: Decodable {
            struct Text: Decodable { let text: String }
            struct Format: Decodable { let mainText: Text?; let secondaryText: Text? }
            let placeId: String
            let text: Text?
            let structuredFormat: Format?
            let types: [String]?
        }
        let suggestions: [Suggestion]?
    }

    private struct PlaceResponse: Decodable {
        struct Name: Decodable { let text: String }
        struct Location: Decodable { let latitude: Double; let longitude: Double }
        let displayName: Name?
        let formattedAddress: String?
        let location: Location?
        let primaryType: String?
        let types: [String]?
    }
}
