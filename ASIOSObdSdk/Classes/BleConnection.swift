import Foundation
import Logging
import CoreBluetooth

typealias BleConnectedHandler = () -> ()
typealias BleReadHandler = (_ data: Data) -> ()
typealias BleDisconnectedHandler = () -> ()

struct BleOptions {
    let onConnected: BleConnectedHandler
    let onDataReceived: BleReadHandler
    let onDisconnected: BleDisconnectedHandler
    
    let serviceUUIDs: [CBUUID]
    
    init(serviceUUIDs: [String],
         onConnected: @escaping BleConnectedHandler,
         onDataReceived: @escaping BleReadHandler,
         onDisconnected: @escaping BleDisconnectedHandler) {
        self.onConnected = onConnected
        self.onDataReceived = onDataReceived
        self.onDisconnected = onDisconnected
        self.serviceUUIDs = serviceUUIDs.map({ (id) -> CBUUID in return CBUUID(string: id) })
    }
}

class BleConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let logger = Logger(label: String(reflecting: BleConnection.self))
    
    let dispatch: DispatchQueue = DispatchQueue.init(label: String(reflecting: BleConnection.self))
    
    var manager: CBCentralManager!
    var periperal: CBPeripheral!
    
    var reader: CBCharacteristic!
    var writer: CBCharacteristic!
    
    var onConnectedHandler: BleConnectedHandler!
    var onReadHandler: BleReadHandler!
    var onDisconnectedHandler: BleDisconnectedHandler!
    
    var options: BleOptions
    
    // MARK: Lifecycle
    
    init(options: BleOptions) {
        self.options = options
        self.onConnectedHandler = options.onConnected
        self.onReadHandler = options.onDataReceived
        self.onDisconnectedHandler = options.onDisconnected
        super.init()
    }

    // MARK: API
    
    public func connect() {
        self.manager = CBCentralManager.init(delegate: self, queue: self.dispatch)
    }
    
    public func write(data: Data) {
        periperal.writeValue(data, for: self.writer, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    public func maxWriteSize() -> Int {
        return self.writer != nil ? writer.service.peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse) : 0
    }
    
    public func isConnected() -> Bool {
        return reader != nil && writer != nil
    }
    
    func disconnect() {}
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("centralManagerDidUpdateState: central.state: \(central.state.rawValue)")
        switch central.state {
            case .poweredOn:
                manager.scanForPeripherals(withServices: options.serviceUUIDs)
            default:
                break
        }
    }
    
    // MARK: CBPeripheralDelegate
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        logger.info("didDiscover: \(String(describing: peripheral.name)) with identifier: \(String(describing: peripheral.identifier))")
        
        periperal = peripheral
        peripheral.delegate = self
        manager.stopScan()
        manager.connect(periperal)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("didDiscover: \(String(describing: peripheral.name)) with identifier: \(String(describing: peripheral.identifier))")
        
        peripheral.discoverServices(options.serviceUUIDs)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.onDisconnectedHandler()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        logger.info("didDiscoverServices: \(String(describing: peripheral.name)) with identifier: \(String(describing: peripheral.identifier))")
        
        periperal.delegate = self
        
        if (manager!.isScanning) {
            manager?.stopScan()
        }
    
        peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first!)!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        logger.info("didDiscoverCharacteristics")
        
        service.characteristics?.forEach({ (characteristic: CBCharacteristic) in
            
            if (characteristic.permissions.contains(CharacteristicPermissions.notify)) {
                logger.info("didDiscoverCharacteristics: read")
                peripheral.setNotifyValue(true, for: characteristic)
                self.reader = characteristic
            }
            
            if (characteristic.permissions.contains(CharacteristicPermissions.write)) {
                logger.info("didDiscoverCharacteristics: write")
                self.writer = characteristic
            }
            
            if isConnected() {
                self.onConnectedHandler()
            }
            
        })
        
    }
       
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            logger.info("ERROR: didUpdateValueFor")
            return
        }
        guard let data = characteristic.value else { return }
        
        let _ = onReadHandler(data)
        
    }
    
}

enum CharacteristicPermissions {
    case read, write, notify
}

extension CBCharacteristic {

    var permissions: Set<CharacteristicPermissions> {

    var permissionsSet = Set<CharacteristicPermissions>()
        
        if self.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.read)
        }
        
        if self.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.write)
        }
        
        if self.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.notify)
        }
        
        return permissionsSet
    }
    
}
