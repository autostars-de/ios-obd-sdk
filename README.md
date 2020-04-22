# <img src="https://autostars.de/assets/logo/logo_green-emblem.png" data-canonical-src="https://autostars.de/assets/logo/logo_green-emblem.png" width="300" /> autostars.de - On Board Diagnosis SDK

## What is the OBD cloud
autostars.de offers an reactive obd sensor cloud which can be used for Car2X integration in your business workflow.
It provides sensor information from your car and fuses sensor information from the mobile device to a session based 
reactive stream and provides this information to multiple connected remote clients.

## Architectural overview
The following section descriptes the real time streaming flow from your car to the cloud infrastructure. 
As shown in the this figure the SDK enables a obd session between the car and cloud. This session consists
of an idenfifier and pincode to secure the flow from third parties.

<img src="https://github.com/autostars-de/ios-obd-sdk/blob/master/Documentation/streaming-flow.png?raw=true" 
data-canonical-src="https://github.com/autostars-de/ios-obd-sdk/blob/master/Documentation/streaming-flow.png?raw=true" width="900" />

The remote client (needs session pincode to access) or the mobile device itself can than send ObdCommands to 
the infrastructure for their session. After the cloud has used the real time channel to the car and evaluated the
protocol an corresponding ObdEvent is emitted and can be consumed via SSE by multiple connected remote clients.

## Requirements

1. Please get in touch at essbach@imoveit.de to get authorization.

2. Get a aupported Bluetooth 4.0 BLE OBD dongle with ELM327 chipset: 

  * [Vgate iCar Pro Bluetooth 4.0](https://www.amazon.de/Vgate-Bluetooth-Fehler-Code-Leser-Adapter/dp/B071D8SYXN)
  * [Veepeak Bluetooth 4.0](https://www.amazon.de/gp/product/B073XKQQQW)
  
## Demo

See the following Youtube Video for further real time demonstration of the flow:

[![OBD Cloud Demo](https://img.youtube.com/vi/ES7c5MUOsAU/0.jpg)](https://www.youtube.com/watch?v=ES7c5MUOsAU)

## Application Interface

You submit so called `OBDCommands` such as `ReadVinNumber` , `ReadErrorCodes` or `DeleteErrorCodes` at the endpoint `https://obd.autostars.de/obd/execute`.

Currently available commands are automatically published at `https://obd.autostars.de/obd/commands`.

  * ReadErrorCodes
        Will read the peding error codes such as P0012 from your car. 
        emits ErrorCodesRead event with corresponding information.
  * DeleteErrorCodes
        Will delete pending error codes from the car.
        emits ErrorCodesDeleted event. *notice* Your car needs a reboot to see the changes.
  
You will receive so called `ObdEvents` such as ErrorCodesRead within your session stream via the Server Sent Events (SSE) at: `https://obd.autostars.de/obd/stream`.

Currently available events are automatically published via the OpenAPI 3.0 Spec here:  `https://obd.autostars.de/internal/swagger.json`.

Example of the `BatteryVoltageRead` event can be seen here:

```
"BatteryVoltageRead" : {
  "type" : "object",
  "required" : [ "voltage" ],
  "properties" : {
    "voltage" : {
      "type" : "string"
    }
  }
}
```

## Installation

Add this SDK `ASIOSObdSdk` to your `Podfile` of your own project and run `pod install`.

Example:
```
platform :ios, '13.0'

target 'YourProject' do
  use_frameworks!
  pod 'ASIOSObdSdk', '~> 1.0.0'
end
```

After this done add this parameters to your `Info.plist` file to access `BLE devices` within the iOS Framework of apple.

* `Privacy - Bluetooth Always Usage Description`
* `Privacy - Bluetooth Peripheral Usage Description`

For `GPS Location` purposes activate

* `NSLocationAlwaysUsageDescription`
* `NSLocationWhenInUseUsageDescription`.
 
 ## Usage of the SDK
 
As a full usage example please refer to the Example Application to be found in this repository. As example application we build an
intelligent milage tracker with real time fuel consumption and location awareness in less than one hour.

Initialize the SDK using the following code and supply the corresponding event handler implementations.
 
```
self.cloud = ApiManager
           .init(options: ApiOptions.init(onConnected: self.onConnected,
                                          onDisconnected: self.onDisconnected,
                                          onBackendEvent: self.onBackendEvent,
                                          onAvailableCommands: self.onAvailableCommands)
           )
           .connect(token: "authorization-token-here")
```

* `onConnected` - Get called when the session to OBD adapter and Backend is established. You will obtain your session credentials.
* `onDisconnected` - Get called when the session was closed.
* `onBackendEvent` - Get called when an event was published with the corresponding ObdEvent like `ErrorCodesRead`
* `onAvailableCommands` - Get called with the currently supported `ObdCommands` to store them in your app.

### Executing an OBD command

After initialization of the SDK executing commands may the main reason to use this cloud for whereas the follwoing code example
can be used

```
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
    self.cloud.execute(command: "ReadRpmNumber")
}
```

As seen it may be useful to execute `ObdCommands` in a interval repeatly like in the example above (every 1 second) but
that depends on your usecase. 


## Example Application

The OBD cloud currently enables _two_ usecases. The first one is directly integrated in the autostars.de Angular 9 frontend
and delivers a nice realtime remote diagnostic tool for german car dealers. The benefit is the direct integration in their daily 
business workflow direct under their domain. The next screenshot shows an example

<img src="https://github.com/autostars-de/ios-obd-sdk/blob/master/Documentation/demo-autostars.png?raw=true" 
data-canonical-src="https://github.com/autostars-de/ios-obd-sdk/blob/master/Documentation/demo-autostars.png?raw=true" width="900" />

The second usecase is the Example application within this repository which uses the current SDK and builds an

 * Intelligent logbook real time consumption, location and live fuel pricing data
 [Logbook](https://github.com/autostars-de/ios-obd-sdk/blob/master/Example/ASIOSObdSdk/ViewController.swift)

As you see there are multiple use cases possible and we are greatful to enable direct
communication within your business workflow. 

## Author
2020 - Jan Essbach <essbach@imoveit.de> for autostars.de™ 
