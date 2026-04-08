import Foundation
internal import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var countryCode: String?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // Kilometer accuracy saves massive amounts of battery and is plenty accurate for a country check
        manager.desiredAccuracy = kCLLocationAccuracyKilometer 
        
        // Eagerly fetch if we already have permission!
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            fetchLocation()
        }
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func fetchLocation() {
        manager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            fetchLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                self.countryCode = "us" // Global English default fallback
                return
            }
            
            if let country = placemarks?.first?.isoCountryCode?.lowercased() {
                self.countryCode = country
            } else {
                self.countryCode = "us"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.countryCode = "us" 
    }
}
