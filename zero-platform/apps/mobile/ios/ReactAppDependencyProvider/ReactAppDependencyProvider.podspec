Pod::Spec.new do |s|
  s.name             = 'ReactAppDependencyProvider'
  s.version          = '0.0.1'
  s.summary          = 'Minimal stub for expo-dev-launcher compatibility.'
  s.description      = 'Header-free stub that satisfies the ReactAppDependencyProvider requirement.'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Zero' => 'dev@example.com' }
  s.platform         = :ios, '15.1'
  s.source           = { :path => '.' }
  s.source_files     = 'RCTAppDependencyProvider.{h,m}'
  # No dependencies - completely standalone
end
