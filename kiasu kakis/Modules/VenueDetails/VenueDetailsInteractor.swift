import Foundation
import CoreLocation

final class VenueDetailsInteractor: VenueDetailsInteractorProtocol {

    let venue: Venue
    private let store: SavedVenuesStoring
    private let queueService: QueueServicing
    private let location: LocationProviding
    private let travel: TravelTimeProviding
    private let places: PlaceDetailsProviding
    private let simulator: QueueSimulating

    init(venue: Venue,
         store: SavedVenuesStoring = SavedVenuesStore.shared,
         queueService: QueueServicing = QueueService.shared,
         location: LocationProviding = LocationService.shared,
         travel: TravelTimeProviding = TravelTimeService(),
         places: PlaceDetailsProviding = GooglePlacesService.shared,
         simulator: QueueSimulating = QueueSimulator.shared) {
        self.venue = venue
        self.store = store
        self.queueService = queueService
        self.location = location
        self.travel = travel
        self.places = places
        self.simulator = simulator
    }

    var activeTicket: QueueTicket? { queueService.activeTicket(forVenue: venue.id) }

    var snapshot: QueueSnapshot { simulator.snapshot(for: venue) }
    var isSaved: Bool { store.isSaved(venue.id) }
    func toggleSaved() { store.toggle(venue.id) }

    func loadPlaceDetails() async -> PlaceDetails? { await places.details(for: venue) }

    func loadPhoto(for details: PlaceDetails) async -> Data? {
        await places.photoData(for: details, venueID: venue.id)
    }

    func loadTravel(requestPermission: Bool) async -> TravelResult {
        switch location.authorization {
        case .notDetermined where !requestPermission: return .needsPermission
        case .denied: return .denied
        default: break
        }
        guard let here = try? await location.currentLocation() else {
            return location.authorization == .denied ? .denied : .unavailable
        }
        let times = await travel.travelTimes(from: here.coordinate,
                                             to: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude))
        return times.fastestMinutes == nil ? .unavailable : .ready(times)
    }
}
