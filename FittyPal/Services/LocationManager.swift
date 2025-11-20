//
//  LocationManager.swift
//  FittyPal
//
//  Manager for handling location services
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        authorizationStatus = locationManager.authorizationStatus
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        #if DEBUG
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        #endif

        // Update properties on main actor
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.currentLocation = location

            // Fetch weather when location is updated
            await WeatherService.shared.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location error: \(error.localizedDescription)")
        #endif
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        #if DEBUG
        let statusName: String
        switch status {
        case .notDetermined: statusName = "Not Determined"
        case .restricted: statusName = "Restricted"
        case .denied: statusName = "Denied"
        case .authorizedAlways: statusName = "Authorized Always"
        case .authorizedWhenInUse: statusName = "Authorized When In Use"
        @unknown default: statusName = "Unknown"
        }
        print("📍 Location authorization changed: \(statusName)")
        #endif

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = status

            if self.isAuthorized {
                #if DEBUG
                print("   ✅ Location authorized, requesting location...")
                #endif
                self.requestLocation()
            } else {
                #if DEBUG
                print("   ❌ Location not authorized")
                #endif
            }
        }
    }
}
