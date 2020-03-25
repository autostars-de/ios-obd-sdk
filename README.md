# autostars.de - On Board Diagnosis SDK

###What is the OBD cloud capable of?
autostars.de offers an reactive obd sensor cloud which can be used for Car2X integration in your business workflow.
It provides sensor information from your car and fuses sensor information from the mobile device to a session based 
reactive stream. 

All you need to obtain to run vehicle diagnostic and fusion of mobile device sensors or build your own use case is 
to have a Bluetooth 4.0 BLE OBD dongle and an authorization-key for your requests against the cloud. Use this SDK 
to integrate easily with your mobile application and be able to to fully run diagnostic of your car in the web.

## Requirements

1. Please get in touch with our team at corporate@autostars.de to get a corporate account for authorization of this SDK.

2. Bluetooth 4.0 BLE OBD dongle

## Demo



## Usage and API

You submit so called `OBDCommands` such as `ReadVinNumber` or `DeleteErrorCodes` at the endpoint

`https://obd.autostars.de/obd/execute`

Currently available commands are automatically published at `https://obd.autostars.de/obd/commands`

```
{
  "commands" : [ "ReadErrorCodes", "DeleteErrorCodes", "ReadConsumptionRate", "ReadRpmNumber", "ReadVinNumber", "ReadBatteryVoltage" ]
}
```

The obd cloud 



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
 




## Publish new version


## Author

2020 autostars.de™ - corporate@autostars.de
