import UIKit
import ASIOSObdSdk
import MapKit
import RxSwift
import ReSwift

class ViewController: UIViewController, MKMapViewDelegate, StoreSubscriber {
    
    @IBOutlet var sessionField: UITextField!
    @IBOutlet var rpmField: UITextField!
    @IBOutlet var gpsField: UITextField!
    @IBOutlet var velocityField: UITextField!
    @IBOutlet var totalMetersField: UITextField!
    @IBOutlet var startSession: UIButton!
    @IBOutlet var mapsView: MKMapView!
    @IBOutlet var totalEvents: UILabel!
    private var line: MKPolyline!
    
    private var cloud: ApiManager!
    private var availableCommands: AvailableCommands!
    
    private let subject: PublishSubject<AppState> = PublishSubject<AppState>.init()
    private let state: AppState = AppState.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cloud = ApiManager
            .init(options: ApiOptions.init(onConnected: self.onConnected,
                                           onDisconnected: self.onDisconnected,
                                           onBackendEvent: self.onBackendEvent,
                                           onAvailableCommands: self.onAvailableCommands)
            )
            .connect(token: "authorization-token-here")
        
        mainStore
            .subscribe(self)
        
        self.mapsView
            .delegate = self
                
        
        let _ = self.subject
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { state in
                self.updateUI(state: state)
            })
    }

    func onConnected(_ session: String) -> () {
        DispatchQueue.main.async {
            self.sessionField.text = session
        }        
    }
    
    @IBAction func executeCommands(sender: UIButton) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.cloud.execute(command: "ReadRpmNumber")
        }
    }
        
    func onBackendEvent(_ event: ObdEvent) -> () {
        
        print(event.short())
        
        switch event.short() {
            case "RpmNumberRead":
                mainStore.dispatch(
                    RpmNumberRead(value: event.attributeString(key: "number"))
                )
            case "LocationRead":
                mainStore.dispatch(
                    LocationRead(value: Location.create(event: event))
                )
            case "DistanceEvaluated":
                mainStore.dispatch(
                    DistanceEvaluated(
                        velocityMetersPerSecond: event.attributeDouble(key: "velocityMetersPerSecond"),
                        travelledInMeters: event.attributeDouble(key: "travelledInMeters")
                    )
                )
            default:
                return
        }
        mainStore.dispatch(EventRead())
    }
    
    func newState(state: AppState) {
        self.subject.onNext(state)
    }
       
    func updateUI(state: AppState) -> () {
        DispatchQueue.main.async {
            self.rpmField.text = state.rpm
            self.totalEvents.text = "\(state.totalEvents)"
            self.velocityField.text = "\(state.velocityKmHours)"
            self.totalMetersField.text = "\(state.totalMeters)"
            if (state.currentLocation != nil) {
                self.gpsField.text = "\(state.currentLocation!.displayName())"
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

