import UIKit
import Foundation
import Logging
import IKEventSource
import SwiftyJSON
import Alamofire

public struct ObdEvent: Codable {
    public let id: String!
    public let name: String!
    public let timestamp: Date!
    public let aggregateId: String!
    public let aggregateRevision: Int!
    public let attributes: JSON!

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case timestamp = "timestamp"
        case aggregateId = "aggregateId"
        case aggregateRevision = "aggregateRevision"
        case attributes = "attributes"
    }
    
    public func has(name: String) -> Bool {
        return short() == name
    }
    
    public func attributeString(key: String) -> String {
         return attributes[key].string!
    }
    
    public func attributeInt(key: String) -> Int {
        return attributes[key].int!
    }
    
    public func attributeDouble(key: String) -> Double {
        return attributes[key].double!
    }
    
    public func short() -> String {
        return name.replacingOccurrences(of: "de.autostars.domain.", with: "")
    }
}

struct DataSocket {
    let ipAddress: String!
    let port: Int!
    
    init(ip: String, port: String) {
        self.ipAddress = ip
        self.port      = Int(port)
    }
}

public struct AvailableCommands: Decodable { public let commands: [String] }

typealias BackendOpenHandler = () -> ()
typealias BackendOnDataHandler = (_ data: Data) -> ()
public typealias BackendOnEventHandler = (_ event: ObdEvent) -> ()
public typealias BackendOnAvailableCommandsHandler = (_ commands: AvailableCommands) -> ()

struct BackendOptions {
    let onOpen: BackendOpenHandler
    let onData: BackendOnDataHandler
    let onEvent: BackendOnEventHandler
    let onAvailableCommand: BackendOnAvailableCommandsHandler
    
    let listen: DataSocket
 
    init(listen: DataSocket,
         onOpen: @escaping BackendOpenHandler,
         onData: @escaping BackendOnDataHandler,
         onEvent: @escaping BackendOnEventHandler,
         onAvailableCommands: @escaping BackendOnAvailableCommandsHandler) {
        self.listen = listen
        self.onOpen = onOpen
        self.onData = onData
        self.onEvent = onEvent
        self.onAvailableCommand = onAvailableCommands
    }
}

class BackendConnection: NSObject, StreamDelegate {
    
    let logger = Logger(label: String(reflecting: BackendConnection.self))
    
    private static let ApiUrl                  = "https://obd.autostars.de/"
    private static let ExecuteUrl              = "\(BackendConnection.ApiUrl)/obd/execute"
    private static let PositionUrl             = "\(BackendConnection.ApiUrl)/obd/position"
    private static let AvailableCommandsUrl    = "\(BackendConnection.ApiUrl)/obd/commands"
    
    private var inputStream: InputStream!
    private var outputStream: OutputStream!

    private var options: BackendOptions
    private var eventSource: EventSource!
    private var login: ObdCustomerLogin!
    
    private var _messagesQueue: Array<Data> = [Data]()
    private var loggedIn = false
    private var loggedInMsg = false
    private let bufferSize = 1024
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS'Z'"
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            return formatter.date(from: try decoder.singleValueContainer().decode(String.self))!
        })
        return decoder
    }()
    
    init(options: BackendOptions) {
        self.options = options
        super.init()
    }
    
    func connect(login: ObdCustomerLogin) {
        self.login = login
        
        Stream.getStreamsToHost(withName: self.options.listen.ipAddress, port: self.options.listen.port,
                                           inputStream: &inputStream, outputStream: &outputStream)
        
        if let inputStream = inputStream, let outputStream = outputStream {
           
            inputStream.delegate = self
            outputStream.delegate = self
            
            inputStream.schedule(in: .main, forMode: .common)
            outputStream.schedule(in: .main, forMode: .common)

            outputStream.open()
            inputStream.open()
            
        }
    }
    
    public func getAvailableCommands() -> () {
        Alamofire
            .request(BackendConnection.AvailableCommandsUrl,
                     method: .get,
                     encoding: JSONEncoding.default)
            .responseJSON { response in
                
                let raw = JSON(response.result.value!)["commands"]
                    .arrayValue
                    .map { (command) -> String in command.stringValue }
            
                self.options.onAvailableCommand(AvailableCommands(commands: raw))
            }
    }
    
    public func listenOnEventStream(challenge: ObdChallenge) -> () {
        
        let url = "\(BackendConnection.ApiUrl)/obd/events?id=\(challenge.id)&token=\(challenge.token)"
        
        eventSource = EventSource(url: URL(string: url)!)
        
        eventSource.onMessage { (id, event, data) in
            
            if (data != nil && (data?.lengthOfBytes(using: .utf8))! > 0) {
                
                do {
                    
                    let data: Data = data!.data(using: .utf8)!
                    
                    let e = try self.decoder.decode(ObdEvent.self, from: data)
                    
                    self.options.onEvent(e)
                
                } catch {
                    self.logger.error("could not unserialize incoming event \(String(describing: data)) \(error)")
                }
                
            }
            
        }
        
        eventSource.connect()
    }
    
    func executeCommand(command: ObdExecuteCommand) -> () {
         Alamofire
             .request(BackendConnection.ExecuteUrl,
                      method: .post,
                      parameters: ["sessionId": command.sessionId, "name": command.name],
                      encoding: JSONEncoding.default)
             .responseJSON { response in
                 self.logger.info("sent command: \(command) \(response)")
             }
     }
     
     func sendCurrentLocation(command: LocationExecuteCommand) -> () {
         Alamofire
             .request(BackendConnection.PositionUrl,
                      method: .post,
                      parameters: ["longitude": command.longitude,
                                   "latitude": command.latitude,
                                   "sessionId": command.sessionId
                      ],
                      encoding: JSONEncoding.default)
             .responseJSON { response in
                 self.logger.info("sent current location: \(command) \(response)")
             }
    }
    
    func write(data: Data) -> () {
        
        if (loggedIn) {
            
            _messagesQueue.insert(data, at: 0)
            writeToStream()
        }
    }
    
    func isInputStream(stream: Stream) -> Bool {
        return stream == inputStream
    }
    
    func isOutputStream(stream: Stream) -> Bool {
        return stream == outputStream
    }
    
    func disconnect() -> () {
        loggedInMsg = false
        loggedIn = false
        
        inputStream.close()
        outputStream.close()
        
        inputStream.remove(from: .main, forMode: .common)
        outputStream.remove(from: .main, forMode: .common)
        
        inputStream  = nil
        outputStream = nil
        
        if (self.eventSource != nil) {
            self.eventSource.disconnect()
            self.eventSource = nil
        }
    }

    func openCompleted() -> () {
        if (inputStream.streamStatus == .open && outputStream.streamStatus == .open && loggedInMsg == false) {
            
            do {
               loggedInMsg = true
               var command = String(data: try JSONEncoder().encode(login),
                  encoding: .utf8
               )
               command?.append("\n")
               _messagesQueue.insert(command!.data(using: .utf8)!, at: 0)
            } catch {
               logger.error("could not write customerLogin")
            }
            
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
          switch eventCode {
            case .openCompleted:
                self.openCompleted()
                break
            case .hasBytesAvailable:
                logger.error(".hasBytesAvailable")
                if (isInputStream(stream: aStream)) {
                    handleIncommingStream(stream: aStream)
                }
                break
            case .hasSpaceAvailable:
                if (isOutputStream(stream: aStream)) {
                    writeToStream()
                }
                break
            default:
                logger.warning("\(aStream): \(eventCode)")
                break
          }
      }
    
     func writeToStream() {
        if _messagesQueue.count > 0 && self.outputStream!.hasSpaceAvailable {                               // maybe threading needed to sync here
            
                //DispatchQueue.main.async {
                    let message = self._messagesQueue.removeLast()                                          // here accessing empty some times
                    self.logger.info(">>>: \(String(describing: String(data: message, encoding: .utf8)))")
                    let _ = self.outputStream!.write(data: message)
                //}
        }
    }
    
    func handleIncommingStream(stream: Stream) {
        //DispatchQueue.main.async {
            var buffer = Array<UInt8>(repeating: 0, count: self.bufferSize)
            let bytesRead = self.inputStream.read(&buffer, maxLength: 1024)
            let data = Data(bytes: buffer, count: bytesRead)
            if (loggedInMsg && !loggedIn) {
                loggedIn = true
                let loginMessage = String(data: data, encoding:.utf8)
                let tokens = loginMessage!.components(separatedBy: CharacterSet.newlines)
              
                self.options.onData((tokens.first?.data(using: .utf8))!)
            } else {
                self.logger.info("<<<: \(String(describing: String(data: data, encoding: .utf8)))")
                self.options.onData(data)
            }
        //}
    }
}

extension OutputStream {
  func write(data: Data) -> Int {
    return data.withUnsafeBytes {
      write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
    }
  }
}
