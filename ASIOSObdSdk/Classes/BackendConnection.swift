import UIKit
import Foundation
import Logging

struct DataSocket {
    let ipAddress: String!
    let port: Int!
    
    init(ip: String, port: String) {
        self.ipAddress = ip
        self.port      = Int(port)
    }
}

typealias BackendOnDataHandler = (_ data: Data) -> ()

struct BackendOptions {
    let onData: BackendOnDataHandler
    let listen: DataSocket
 
    init(listen: DataSocket,
         onData: @escaping BackendOnDataHandler) {
        self.listen = listen
        self.onData = onData
    }
}

class BackendConnection: NSObject, StreamDelegate {
    
    let logger = Logger(label: String(reflecting: BackendConnection.self))
    
    private var inputStream: InputStream!
    private var outputStream: OutputStream!

    public var connected: Bool = false
    
    private var options: BackendOptions
    
    private var onDataHandler: BackendOnDataHandler
    
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
