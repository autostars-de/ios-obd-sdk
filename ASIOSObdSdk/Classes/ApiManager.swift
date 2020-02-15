import Foundation
import CoreBluetooth
import Logging

public typealias ConnectedHandler = (_ sessionId: String) -> ()
public typealias DisconnectedHandler = () -> ()

public struct ApiOptions {
    let onConnected: ConnectedHandler
    let onDisconnected: DisconnectedHandler
    let socket: DataSocket = DataSocket(ip: "autostars.de", port: "8898")
    
    public init(onConnected: @escaping ConnectedHandler, onDisconnected: @escaping DisconnectedHandler) {
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
    }
}

public class ApiManager: NSObject, StreamDelegate {
    
    let logger = Logger(label: String(reflecting: ApiManager.self))
    let socket = DataSocket(ip: "autostars.de", port: "8898")
    
    private var bluetooth: BleConnection!
    private var backend: BackendConnection!
    
    private var initialized: Bool   = false
    private var sessionId: String   = ""
    private var token: String       = ""
    
    private let options: ApiOptions
    
    public init(options: ApiOptions) {
        self.options = options
        
        super.init()
        
        bluetooth = BleConnection.init(
            options: BleOptions.init(serviceUUIDs: ["0x18F0"],
            onConnected: self.onBleConnected,
            onDataReceived: self.onBleDataReceived,
            onDisconnected: self.onBleDisconnected
        ))
        
        backend = BackendConnection.init(
            options: BackendOptions
                .init(listen: socket, onData: self.onBackendDataReceived)
        )
    }
    
    public func connect(token: String) -> Void {
        self.token = token
        bluetooth.connect()
    }
    
    private func onBleConnected() -> () {
        logger.info("onBleConnected")
        
        backend.connect()
    }
    
    private func onBleDisconnected() -> () {
        self.initialized = false
        
        backend.disconnect()
        bluetooth.connect()
        
        self.options.onDisconnected()
        logger.info("onBleDisconnected")
    }
    
    private func onBackendDataReceived(data: Data) -> () {
        
        if (initialized) {
            logger.info(">>>: \(String(describing: String(data: data, encoding: .ascii)))")
            bluetooth.write(data: data)
        } else {
            initialized = true
            sessionId = String(data: data, encoding: .ascii)!
            let _ = backend.write(data: "\(self.token)\n".data(using: .ascii)!)
            logger.info("onBackendDataReceived-initialized: sessionId: \(self.sessionId) token: \(self.token)")
            self.options.onConnected(sessionId)
        }
        
    }
        
    private func onBleDataReceived(data: Data) -> () {
        let _ = backend.write(data: data)
        logger.info("<<<: \(String(describing: String(data: data, encoding: .ascii)))")
    }
    
}
