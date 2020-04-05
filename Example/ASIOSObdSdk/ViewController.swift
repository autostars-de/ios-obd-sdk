import UIKit
import ASIOSObdSdk
import MapKit

class ViewController: UIViewController, MKMapViewDelegate    {

    @IBOutlet var sessionField: UITextField!
    @IBOutlet var rpmField: UITextField!
    @IBOutlet var gpsField: UITextField!
    @IBOutlet var velocityField: UITextField!
    @IBOutlet var totalMetersField: UITextField!
    
    @IBOutlet var startSession: UIButton!
    
    @IBOutlet var mapsView: MKMapView!
    
    @IBOutlet var totalEvents: UILabel!
    
    private var cloud: ApiManager!
    private var availableCommands: AvailableCommands!
    
    private var locations: [Location] = []
    private var countEvents = 0
    private var totalMeters = 0.0
    private var line: MKPolyline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapsView.delegate = self
        
        self.cloud = ApiManager
            .init(options: ApiOptions.init(onConnected: self.onConnected,
                                           onDisconnected: self.onDisconnected,
                                           onBackendEvent: self.onBackendEvent,
                                           onAvailableCommands: self.onAvailableCommands)
            )
            .connect(token: "authorization-token-here")
    }

    func onConnected(_ session: String) -> () {
        DispatchQueue.main.async {
            self.sessionField.text = session
        }        
    }
    
    @IBAction func executeCommands(sender: UIButton) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.cloud.execute(command: "ReadRpmNumber")
            self.cloud.execute(command: "ReadConsumptionRate")
        }
    }
        
    func onBackendEvent(_ event: ObdEvent) -> () {
        DispatchQueue.main.async {
            if (event.has(name: "RpmNumberRead")) {
                self.rpmField.text = event.attributeString(key: "number")
            }
            if (event.has(name: "LocationRead")) {
                
                let location = Location.create(event: event)
                
                self.gpsField.text = location.displayName()
                self.mapsView.setRegion(location.region(), animated: true)
                
                
                if (self.line != nil) {
                    self.mapsView.remove(self.line)
                }
                
                self.locations.append(location)
                
                let x = self.locations.map { (location) -> CLLocationCoordinate2D in
                    location.center()
                }
                self.line = MKPolyline(coordinates: x, count: x.count)
                self.mapsView.add(self.line)
            }
            if (event.has(name: "DistanceEvaluated")) {
                self.velocityField.text = "\(event.attributeDouble(key: "velocityMetersPerSecond") * 3.6)"
                self.totalMeters = self.totalMeters + event.attributeDouble(key: "travelledInMeters")
                self.totalMetersField.text = "\(self.totalMeters)"
            }
            self.countEvents = self.countEvents + 1
            self.totalEvents.text = "\(self.countEvents)"
        }
    }
    
    func onAvailableCommands(_ commands: AvailableCommands) -> () {
        self.availableCommands = commands
    }
       
    func onDisconnected() -> () {
        DispatchQueue.main.async {
            self.sessionField.isHidden = true
            self.sessionField.text = ""
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let testlineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        testlineRenderer.strokeColor = .black
        testlineRenderer.lineWidth = 2.0
        return testlineRenderer
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

