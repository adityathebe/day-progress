import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var locationError: String?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        // City-level accuracy is plenty for sunrise/sunset
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Call this when entering Daylight mode. Asks for permission if needed,
    /// then fires a single location request.
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // delegate will call requestLocation() again once authorized
        case .authorized, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            locationError =
                "Location access denied. Enable it in System Settings → Privacy & Security → Location Services."
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            self.authorizationStatus = status
            if status == .authorized || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.coordinate = location.coordinate
            self.locationError = nil
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.locationError = error.localizedDescription
        }
    }
}
