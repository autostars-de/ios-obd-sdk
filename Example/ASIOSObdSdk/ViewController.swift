import UIKit
import ASIOSObdSdk
import MapKit

class ViewController: UIViewController {

    @IBOutlet var sessionField: UITextField!
    @IBOutlet var rpmField: UITextField!
    
    @IBOutlet var startSession: UIButton!
    
    @IBOutlet var mapsView: MKMapView!
    
    private var cloud: ApiManager!
    private var availableCommands: AvailableCommands!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.cloud.execute(command: "ReadRpmNumber")
    }
        
    func onBackendEvent(_ event: ObdEvent) -> () {
        DispatchQueue.main.async {
            if (event.has(name: "RpmNumberRead")) {
                self.rpmField.text = event.attributeString(key: "number")
            }
            if (event.has(name: "GpsPositionRead")) {
                
                let location = Location
                    .init(
                        longitudeValue: event.attributeDouble(key: "latidude"),
                        latitudeValue: event.attributeDouble(key: "longitude")
                    )
                
                self.mapsView.setRegion(location.region(), animated: true)
                self.mapsView.addAnnotation(location.annotation())
                
            }
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

