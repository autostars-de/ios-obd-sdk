import Foundation
import CoreBluetooth
import Logging

public typealias ConnectedHandler = (_ sessionId: String) -> ()
public typealias DisconnectedHandler = () -> ()
public typealias BackendEventHandler = (_ event: ObdEvent) -> ()

public struct ObdExecuteCommand: Codable {
    let sessionId: String
    let name: String
    
    init(sessionId: String, name: String) {
        self.sessionId = sessionId
        self.name = name
    }
}

public struct ApiOptions {
    let onConnected: ConnectedHandler
    let onDisconnected: DisconnectedHandler
    let onBackendEventReceived: BackendEventHandler
    let onBackendAvailableCommands: BackendOnAvailableCommandsHandler
    
    let socket: DataSocket = DataSocket(ip: "autostars.de", port: "8898")
    
    public init(onConnected: @escaping ConnectedHandler,
                onDisconnected: @escaping DisconnectedHandler,
                onBackendEvent: @escaping BackendEventHandler,
                onAvailableCommands: @escaping BackendOnAvailableCommandsHandler) {
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onBackendEventReceived = onBackendEvent
        self.onBackendAvailableCommands = onAvailableCommands
    }
}

public class ApiManager: NSObject, StreamDelegate {
    
    let logger = Logger(label: String(reflecting: ApiManager.self))
    
    let supportedAdapters = [
        "0x18F0",  // Vgate iCar Pro Bluetooth 4.0
        "0xFFF0"   // Veepeak Bluetooth 4.0
    ]
    
    private var bluetooth: BleConnection!
    private var backend: BackendConnection!
    private var location: LocationService!
    
    private var initialized: Bool   = false
    private var sessionId: String   = ""
    private var token: String       = ""
    
    private let options: ApiOptions
    
    public init(options: ApiOptions) {
        self.options = options
        
        super.init()
        
        bluetooth = BleConnection.init(
            options: BleOptions.init(serviceUUIDs: self.supportedAdapters,
            onConnected: self.onBleConnected,
            onDataReceived: self.onBleDataReceived,
            onDisconnected: self.onBleDisconnected
        ))
        
        backend = BackendConnection.init(
            options: BackendOptions
                .init(listen: self.options.socket,
                      onData: self.onBackendDataReceived,
                      onEvent: options.onBackendEventReceived,
                      onAvailableCommands: options.onBackendAvailableCommands
            )
        )
        
        
    }
    
    public func connect(token: String) -> ApiManager {
        self.token = token
        bluetooth.connect()
        return self
    }
    
    private func onLocationUpdated(_ location: Location) -> () {
        let command = LocationExecuteCommand
            .init(sessionId: self.sessionId,
                  longitudeValue: location.longitude,
                  latitudeValue: location.latitude
        )
        self.backend.sendCurrentLocation(command: command)
    }
    
    public func execute(command: String) -> () {
        let command = ObdExecuteCommand(sessionId: self.sessionId, name: command)
        self.backend.executeCommand(command: command)
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
            
            
            location = LocationService.init(options: LocationOptions.init(onLocationUpdated: self.onLocationUpdated))
            location.register()
            
            self.options.onConnected(sessionId)
        }
        
    }
        
    private func onBleDataReceived(data: Data) -> () {
        let _ = backend.write(data: data)
        logger.info("<<<: \(String(describing: String(data: data, encoding: .ascii)))")
    }
    
}
