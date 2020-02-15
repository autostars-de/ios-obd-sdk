# autostars.de - On Board Diagnosis SDK

## Description

Use this SDK to integrate the OBD cloud of autostars.de easily in your mobile application and be
able to use OBD Bluetooth dongles such as the ELM327 to fully run diagnostic of your car in the web.

## Requirements

Please get in touch with our team at corporate@autostars.de to get a corporate account for authorization of this SDK.

## Demo



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

## Usage and API



## Publish new version


## Author

2020 autostars.de™ - corporate@autostars.de
