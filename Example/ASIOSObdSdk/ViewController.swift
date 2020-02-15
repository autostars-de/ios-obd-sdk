import UIKit
import ASIOSObdSdk

class ViewController: UIViewController {

    @IBOutlet var sessionLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ApiManager
            .init(options: ApiOptions.init(onConnected: self.onConnected, onDisconnected: self.onDisconnected))
            .connect(token: "authorization-token-here")
    }

    func onConnected(_ session: String) -> () {
        DispatchQueue.main.async {
            self.sessionLabel.isHidden = false
            self.sessionLabel.text = session
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

