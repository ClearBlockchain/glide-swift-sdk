Pod::Spec.new do |s|
  s.name              = 'GlideSwiftSDK'
  s.version           = '1.0.1'
  s.summary           = 'A Glide Swift SDK'
  s.homepage          = 'https://github.com/ClearBlockchain/glide-swift-sdk'
  s.license           = { type: 'MIT' }
  s.author            = { 'Glide' => 'amiravisar89@gmail.com' }
  s.documentation_url = 'https://github.com/ClearBlockchain/glide-swift-sdk/blob/master/README.md'

  s.ios.deployment_target  = '15.0'
  s.swift_version          = '5.9'


  s.source = { git: 'https://github.com/ClearBlockchain/glide-swift-sdk.git',
               tag: s.version }

  s.source_files = 'Sources/**/*.{swift}'

  s.dependency 'JWTDecode', '3.1.0'

  s.requires_arc = true

end
