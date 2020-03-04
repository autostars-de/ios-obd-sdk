import UIKit
import ASIOSObdSdk
import MapKit

class ViewController: UIViewController {

    @IBOutlet var sessionField: UITextField!
    @IBOutlet var rpmField: UITextField!
    @IBOutlet var gpsField: UITextField!
    @IBOutlet var consumptionRateField: UITextField!
    
    @IBOutlet var startSession: UIButton!
    
    @IBOutlet var mapsView: MKMapView!
    
    @IBOutlet var totalEvents: UILabel!
    
    private var cloud: ApiManager!
    private var availableCommands: AvailableCommands!
    
    private var countEvents = 0
    
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
                self.mapsView.addAnnotation(location.annotation())
            }
            if (event.has(name: "ConsumptionRateRead")) {
                self.consumptionRateField.text = event.attributeString(key: "consumption")
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

