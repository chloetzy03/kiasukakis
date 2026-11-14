import CoreLocation

protocol TicketTravelUpdating: AnyObject {
    var locationStatus: LocationAuthorization { get }
    // Works out how far the user is from the venue and stores it on the ticket. Never asks for permission unless told to.
    func refresh(ticketID: UUID, requestPermission: Bool) async
    func refreshAllActive() async
    // How far the user is from the venue, or nil if their location isn't available. Never asks for permission.
    func distanceToVenue(ticketID: UUID) async -> CLLocationDistance?
}

// How close counts as "already there" (metres). Within this, the ticket is checked in automatically.
let arrivalRadiusMetres: CLLocationDistance = 100
// Farther than this and "I'm here" asks the user to confirm, because they probably haven't arrived.
let farFromVenueMetres: CLLocationDistance = 300

final class TicketTravelUpdater: TicketTravelUpdating {

    private let location: LocationProviding
    private let travel: TravelTimeProviding
    private let venues: VenueProviding
    private let service: QueueServicing

    init(location: LocationProviding = LocationService.shared,
         travel: TravelTimeProviding = TravelTimeService(),
         venues: VenueProviding = VenueRepository.shared,
         service: QueueServicing = QueueService.shared) {
        self.location = location
        self.travel = travel
        self.venues = venues
        self.service = service
    }

    var locationStatus: LocationAuthorization { location.authorization }

    func refreshAllActive() async {
        for ticket in service.tickets where ticket.status.isActive && ticket.arrivedAt == nil {
            await refresh(ticketID: ticket.id, requestPermission: false)
        }
    }

    func distanceToVenue(ticketID: UUID) async -> CLLocationDistance? {
        guard let ticket = service.ticket(id: ticketID), let venue = venues.venue(id: ticket.venueID),
              location.authorization == .authorized, let here = try? await location.currentLocation() else { return nil }
        return here.distance(from: CLLocation(latitude: venue.latitude, longitude: venue.longitude))
    }

    func refresh(ticketID: UUID, requestPermission: Bool) async {
        guard let ticket = service.ticket(id: ticketID), ticket.status.isActive, ticket.arrivedAt == nil,
              let venue = venues.venue(id: ticket.venueID) else { return }
        // Asking for location is the user's choice, so background refreshes stay quiet until it is granted.
        guard requestPermission || location.authorization == .authorized else { return }
        guard let here = try? await location.currentLocation() else { return }

        let place = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
        if here.distance(from: place) <= arrivalRadiusMetres {
            service.checkIn(ticketID: ticketID)
            return
        }
        let times = await travel.travelTimes(from: here.coordinate, to: place.coordinate)
        if let minutes = times.fastestMinutes { service.setTravelMinutes(minutes, forTicket: ticketID) }
    }
}
