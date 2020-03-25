# autostars.de - On Board Diagnosis SDK

## What is the OBD cloud
autostars.de offers an reactive obd sensor cloud which can be used for Car2X integration in your business workflow.
It provides sensor information from your car and fuses sensor information from the mobile device to a session based 
reactive stream. 

All you need to obtain to run vehicle diagnostic and fusion of mobile device sensors or build your own use case is 
to have a Bluetooth 4.0 BLE OBD dongle and an authorization-key for your requests against the cloud. Use this SDK 
to integrate easily with your mobile application and be able to to fully run diagnostic of your car in the web.

## Requirements

1. Please get in touch with our team at essbach@imoveit.de to get a corporate account for authorization of this SDK.

2. Bluetooth 4.0 BLE OBD dongle see: 

[Vgate iCar Pro Bluetooth 4.0](https://www.amazon.de/Vgate-Bluetooth-Fehler-Code-Leser-Adapter/dp/B071D8SYXN)

## Demo

See the following Youtube Video for further real time demonstration of the flow:

[![OBD Cloud Demo](https://img.youtube.com/vi/ES7c5MUOsAU/0.jpg)](https://www.youtube.com/watch?v=ES7c5MUOsAU)

## Application Interface

You submit so called `OBDCommands` such as `ReadVinNumber` or `DeleteErrorCodes` at the endpoint

`https://obd.autostars.de/obd/execute`

Currently available commands are automatically published at `https://obd.autostars.de/obd/commands`

```
{
  "commands" : [ "ReadErrorCodes", "DeleteErrorCodes", "ReadConsumptionRate", "ReadRpmNumber", "ReadVinNumber", "ReadBatteryVoltage" ]
}
```

You will receive so called ObdEvents within your Session Stream via the Server Sent Events (SSE) stream at:

`https://obd.autostars.de/obd/stream`

Currently available events are automatically published via the OpenAPI 3.0 Spec here:  `https://obd.autostars.de/internal/swagger.json`

Example of one Event could be:

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

After this done add this parameters to your `Info.plist` file to access BLE devices within the iOS Framework of apple.

`Privacy - Bluetooth Always Usage Description`
`Privacy - Bluetooth Peripheral Usage Description`

For Location GPS purposes activate
`NSLocationAlwaysUsageDescription`
`NSLocationWhenInUseUsageDescription` in your `Info.plist`.
 
 ## Usage of the SDK
 
 For full example please refer to the Example Application which represents an intelligent milage tracker with real time fuel consumption.
 
 Initialize the SDK using the following code and supply the corresponding eventhandler implementations.
 
```
self.cloud = ApiManager
           .init(options: ApiOptions.init(onConnected: self.onConnected,
                                          onDisconnected: self.onDisconnected,
                                          onBackendEvent: self.onBackendEvent,
                                          onAvailableCommands: self.onAvailableCommands)
           )
           .connect(token: "authorization-token-here")
```

Full example Implementation: [Example Usage within Example App](https://github.com/autostars-de/ios-obd-sdk/blob/master/Example/ASIOSObdSdk/ViewController.swift)

## Author
2020 - Jan Essbach <essbach@imoveit.de> for autostars.de™ 
