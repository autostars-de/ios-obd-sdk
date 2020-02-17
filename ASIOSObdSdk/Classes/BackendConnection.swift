import UIKit
import Foundation
import Logging
import IKEventSource
import SwiftyJSON

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
    
    private func short() -> String {
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

typealias BackendOnDataHandler = (_ data: Data) -> ()
public typealias BackendOnEventHandler = (_ event: ObdEvent) -> ()

struct BackendOptions {
    let onData: BackendOnDataHandler
    let onEvent: BackendOnEventHandler
    
    let listen: DataSocket
 
    init(listen: DataSocket,
         onData: @escaping BackendOnDataHandler,
         onEvent: @escaping BackendOnEventHandler) {
        self.listen = listen
        self.onData = onData
        self.onEvent = onEvent
    }
}

class BackendConnection: NSObject, StreamDelegate {
    
    let logger = Logger(label: String(reflecting: BackendConnection.self))
    
    private var inputStream: InputStream!
    private var outputStream: OutputStream!

    public var connected: Bool = false
    
    private var options: BackendOptions
    
    private var onDataHandler: BackendOnDataHandler
    
    private var eventSource: EventSource!
    
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
        self.onDataHandler = options.onData
        super.init()
    }
    
    func connect() {
        Stream.getStreamsToHost(withName: self.options.listen.ipAddress, port: self.options.listen.port,
                                           inputStream: &inputStream, outputStream: &outputStream)
        
        if let inputStream = inputStream, let outputStream = outputStream {
           
            inputStream.delegate = self
            
            inputStream.schedule(in: .main, forMode: .common)
            outputStream.schedule(in: .main, forMode: .common)

            inputStream.open()
            outputStream.open()
                        
            connected = true
            listenOnEventStream()
            
        }
    }
    
    private func listenOnEventStream() -> () {
        eventSource = EventSource(url: URL(string: "https://obd.autostars.de/obd/events")!)
        
        eventSource.onMessage { (id, event, data) in
            
            if (data != nil && (data?.lengthOfBytes(using: .utf8))! > 0) {
                
                do {
                    
                    let data: Data = data!.data(using: .utf8)!
                    
                    let e = try self.decoder.decode(ObdEvent.self, from: data)
                    
                    self.options.onEvent(e)
                
                } catch {
                    self.logger.error("could not unserialize incoming event \(String(describing: data))  \(error)")
                }
                
            }
            
        }
        
        eventSource.connect()
    }
    
    private func disconnectEventStream() {
        if (self.eventSource != nil) {
            self.eventSource.disconnect()
            self.eventSource = nil
        }
    }
    
    func isConnected() -> Bool {
        return connected;
    }
        
    func write(data: Data) -> () {
        let _ = outputStream.write(data: data)
    }
    
    func isInputStream(stream: Stream) -> Bool {
        return stream == inputStream
    }
    
    func isOutputStream(stream: Stream) -> Bool {
        return stream == outputStream
    }
    
    func disconnect() -> () {
        inputStream.close()
        outputStream.close()
        
        inputStream.remove(from: .main, forMode: .common)
        outputStream.remove(from: .main, forMode: .common)
        
        inputStream  = nil
        outputStream = nil
        
        disconnectEventStream()
        
        connected    = false
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
          switch eventCode {
              case .hasBytesAvailable:
                let input = aStream as! InputStream
                while (input.hasBytesAvailable) {
                    
                    let bufferSize = 1024
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                    
                    defer {
                        buffer.deallocate()
                    }
                    
                    while input.hasBytesAvailable {
                        self.onDataHandler(Data(bytes: buffer, count: input.read(buffer, maxLength: bufferSize)))
                    }
                }
                break
              default:
                 break
          }
      }
    
}

extension OutputStream {
  func write(data: Data) -> Int {
    return data.withUnsafeBytes {
      write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
    }
  }
}
