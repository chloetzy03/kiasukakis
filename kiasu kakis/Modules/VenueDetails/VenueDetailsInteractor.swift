import Foundation
import CoreLocation

final class VenueDetailsInteractor: VenueDetailsInteractorProtocol {

    let venue: Venue
    private let store: SavedVenuesStoring
    private let queueService: QueueServicing
    private let location: LocationProviding
    private let travel: TravelTimeProviding

    init(venue: Venue,
         store: SavedVenuesStoring = SavedVenuesStore.shared,
         queueService: QueueServicing = QueueService.shared,
         location: LocationProviding = LocationService.shared,
         travel: TravelTimeProviding = TravelTimeService()) {
        self.venue = venue
        self.store = store
        self.queueService = queueService
        self.location = location
        self.travel = travel
    }

    var activeTicket: QueueTicket? { queueService.activeTicket(forVenue: venue.id) }

    var snapshot: QueueSnapshot { DemoVenueData.snapshot(for: venue.id) }
    var isSaved: Bool { store.isSaved(venue.id) }
    func toggleSaved() { store.toggle(venue.id) }

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
