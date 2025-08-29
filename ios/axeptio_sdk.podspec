#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint axeptio_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'axeptio_sdk'
  s.version          = '2.0.15'
  s.summary          = 'AxeptioSDK for presenting cookies consent to the user'
  s.homepage         = 'https://github.com/axeptio/flutter-sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Axeptio' => 'support@axeptio.eu' }
  s.source           = { :git => "https://github.com/axeptio/flutter-sdk.git" }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency "AxeptioIOSSDK", "2.0.15"
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.6'
end
