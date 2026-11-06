import CoreLocation

enum LocationAuthorization {
    case notDetermined
    case denied
    case authorized
}

enum LocationError: Error {
    case denied
    case unavailable
}

protocol LocationProviding: AnyObject {
    var authorization: LocationAuthorization { get }
    func currentLocation() async throws -> CLLocation
}

// Wraps CLLocationManager so the rest of the app can simply `await` the user's location.
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    var authorization: LocationAuthorization {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        default: return .denied
        }
    }

    func currentLocation() async throws -> CLLocation {
        if authorization == .notDetermined { await requestAuthorization() }
        guard authorization == .authorized else { throw LocationError.denied }

        locationContinuation?.resume(throwing: LocationError.unavailable)
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func requestAuthorization() async {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.unavailable)
        locationContinuation = nil
    }
}
