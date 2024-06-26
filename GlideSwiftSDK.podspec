

Pod::Spec.new do |s|
  s.name         = 'GlideSwiftSDK'
  s.version      = '1.0.0'
  s.summary      = 'A Glide Swift SDK'
  s.homepage     = 'https://github.com/ClearBlockchain/glide-swift-sdk'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Glide' => 'amiravisar89@gmail.com' }
  s.source       = { :git => 'https://github.com/ClearBlockchain/glide-swift-sdk.git', :tag => s.version.to_s }
  s.platform     = :ios, '17.0'
  s.source_files = 'Sources/GlideSwiftSDK/**/*.{swift}'
  s.requires_arc = true
  s.dependency 'JWTDecode', '3.1.0'
  s.ios.deployment_target  = '17.0'
  s.swift_version          = '5.9'

end
