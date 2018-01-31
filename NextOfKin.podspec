Pod::Spec.new do |s|
  s.name             = 'NextOfKin'
  s.version          = '0.1.0'
  s.summary          = 'Helpful additions to the official kin-ios-core-sdk'
  s.description      = <<-DESC
                       NextOfKin is an RxSwift interface to access the official kin-sdk-core-ios ( https://github.com/kinfoundation/kin-sdk-core-ios )
                       DESC

  s.homepage         = 'https://github.com/Blahartinger/NextOfKin-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bryan Lahartinger' => 'Bryan.Lahartinger@kik.com' }
  s.source           = { :git => 'https://github.com/Blahartinger/NextOfKin-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'NextOfKin/Classes/**/*'

  s.ios.deployment_target = '8.0'
  s.platform = :ios, '8.0'

  s.dependency 'RxSwift',    '~> 4.0'
  s.dependency 'KeychainAccess', '~> 3.1.0'
  s.dependency 'KinSDK', '~> 0.3.9'
end
