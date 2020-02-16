import UIKit
import ASIOSObdSdk

class ViewController: UIViewController {

    @IBOutlet var sessionLabel: UITextField!
    @IBOutlet var eventsTextView: UITextView!
        
    private let df = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        df.dateFormat = "dd.MM hh:mm:ss"
        
        ApiManager
            .init(options:
                    ApiOptions.init(onConnected: self.onConnected,
                                    onDisconnected: self.onDisconnected,
                                    onBackendEvent: self.onBackendEvent
                )
            )
            .connect(token: "authorization-token-here")
    }

    func onConnected(_ session: String) -> () {
        DispatchQueue.main.async {
            self.sessionLabel.isHidden = false
            self.sessionLabel.text = session
        }
    }
    
    func onBackendEvent(_ event: ObdEvent) -> () {
        DispatchQueue.main.async {
            self.eventsTextView.text += "\n" + (self.df.string(from: event.timestamp) + " - " + event.short())
        }
    }
    
    func onDisconnected() -> () {
        DispatchQueue.main.async {
            self.sessionLabel.isHidden = true
            self.sessionLabel.text = ""
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

