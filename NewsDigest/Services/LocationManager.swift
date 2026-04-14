import Foundation
internal import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    @Published var countryCode: String?
    @Published var localArea: String? // Captures City, State for hyper-local impact
    @Published var overriddenLocation: String? // Manually entered value
    @Published var authorizationStatus: CLAuthorizationStatus
    
    var displayLocation: String {
        overriddenLocation ?? localArea ?? countryCode?.uppercased() ?? "the World"
    }
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer 
        
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
                self.localArea = nil
                return
            }
            
            if let placemark = placemarks?.first {
                self.countryCode = placemark.isoCountryCode?.lowercased() ?? "us"
                
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                
                if !city.isEmpty && !state.isEmpty {
                    self.localArea = "\(city), \(state)"
                } else if !city.isEmpty {
                    self.localArea = city
                } else {
                    self.localArea = placemark.country
                }
            } else {
                self.countryCode = "us"
                self.localArea = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.countryCode = "us" 
    }
}

