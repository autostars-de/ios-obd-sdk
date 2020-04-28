import Foundation
import MapKit
import CoreLocation
import Logging

public typealias OnLocationUpdatedHandler = (_ location: Location) -> ()

public struct LocationExecuteCommand: Codable {
    let longitude: Double
    let latitude: Double
    let sessionId: String
    
    public init(sessionId: String, longitudeValue: Double, latitudeValue: Double) {
        self.sessionId = sessionId
        self.longitude = longitudeValue
        self.latitude = latitudeValue
    }
}

public struct Location {
   let longitude: CLLocationDegrees
   let latitude: CLLocationDegrees
    
   public static func create(event: ObdEvent) -> Location {
      return Location.init(longitudeValue: event.attributeDouble(key: "longitude"), latitudeValue: event.attributeDouble(key: "latitude"))
   }
    
   public init(longitudeValue: Double, latitudeValue: Double) {
       self.longitude = CLLocationDegrees.init(longitudeValue)
       self.latitude = CLLocationDegrees.init(latitudeValue)
   }
    
   public init(longitude: CLLocationDegrees, latitude: CLLocationDegrees) {
       self.longitude = longitude
       self.latitude = latitude
   }
    
   public func center() -> CLLocationCoordinate2D {
       return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
   }
    
   public func region() -> MKCoordinateRegion {
       return MKCoordinateRegion(center: self.center(), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
   }
    
   public func annotation() -> MKPointAnnotation {
       let annotation = MKPointAnnotation()
       annotation.coordinate = self.center()
       return annotation
   }
    
   public func displayName() -> String {
        return "\(longitude) \(latitude)"
   }
}

struct LocationOptions {
    let onLocationUpdated: OnLocationUpdatedHandler
    
    init(onLocationUpdated: @escaping OnLocationUpdatedHandler) {
        self.onLocationUpdated = onLocationUpdated
    }
}

class LocationService: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
        
    var options: LocationOptions
      
    // MARK: Lifecycle
      
    init(options: LocationOptions) {
      self.options = options
      super.init()
    }

    func register() -> () {
        // Ask for Authorisation from the User.
       self.locationManager.requestAlwaysAuthorization()

       // For use in foreground
       self.locationManager.requestWhenInUseAuthorization()

       if CLLocationManager.locationServicesEnabled() {
           locationManager.delegate = self
           locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
           locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
           locationManager.startUpdatingLocation()
       }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
       self.options.onLocationUpdated(Location.init(longitude: locValue.longitude, latitude: locValue.latitude))
    }
    
}
