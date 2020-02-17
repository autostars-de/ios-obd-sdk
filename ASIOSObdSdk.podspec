Pod::Spec.new do |s|
  s.name             = 'ASIOSObdSdk'
  s.version          = '1.0.0'
  s.summary          = 'This SDK encapsulates the communication with the obd cloud of autostars.de'
  s.description      = <<-DESC
Use this SDK as easy integration method of obd cloud of autostars.de. Please get a corporate account by contacting
autostars.de. Use your access-token to fully authorize your application.
                       DESC
  s.homepage              = 'https://github.com/autostars-de/ios-obd-sdk'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Jan Essbach' => 'jan.essbach@imoveit.de' }
  s.source                = { :git => 'https://github.com/autostars-de/ios-obd-sdk.git', :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/janessbach'
  s.swift_version         = '4.2'
  s.ios.deployment_target = '13.0'
  s.source_files          = 'ASIOSObdSdk/Classes/**/*'
  s.frameworks            = 'CoreBluetooth', 'Foundation', 'UIKit'
  s.dependency              'Logging', '~> 1.1'
  s.dependency              'IKEventSource', '~> 3.0.1'
  s.dependency              'SwiftyJSON', '~> 4.2.0'
end
