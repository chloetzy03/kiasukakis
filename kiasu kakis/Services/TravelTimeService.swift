import MapKit

struct TravelTimes: Equatable {
    let walkingMinutes: Int?
    let drivingMinutes: Int?

    var fastestMinutes: Int? { [walkingMinutes, drivingMinutes].compactMap { $0 }.min() }
}

protocol TravelTimeProviding: AnyObject {
    func travelTimes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> TravelTimes
}

// Asks Apple Maps (MKDirections) how long the trip would take on foot and by car.
final class TravelTimeService: TravelTimeProviding {

    func travelTimes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> TravelTimes {
        async let walking = estimatedMinutes(from: start, to: end, transport: .walking)
        async let driving = estimatedMinutes(from: start, to: end, transport: .automobile)
        return await TravelTimes(walkingMinutes: walking, drivingMinutes: driving)
    }

    private func estimatedMinutes(from start: CLLocationCoordinate2D,
                                  to end: CLLocationCoordinate2D,
                                  transport: MKDirectionsTransportType) async -> Int? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transport
        guard let response = try? await MKDirections(request: request).calculateETA() else { return nil }
        return max(1, Int((response.expectedTravelTime / 60).rounded(.up)))
    }
}
