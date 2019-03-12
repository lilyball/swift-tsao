Pod::Spec.new do |s|
  s.name         = "swift-tsao"
  s.version      = "3.0.2"
  s.summary      = "Type-Safe Associated Objects in Swift"
  s.description  = <<-DESC
    TSAO is an implementation of type-safe associated objects in Swift. 
    Objective-C associated objects are useful, but they are also untyped; 
    every associated object is only known to be id at compile-time and 
    clients must either test the class at runtime or rely on it being the 
    expected type.
                   DESC

  s.homepage     = "https://github.com/kballard/swift-tsao"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Lily Ballard" => "lily@sb.org" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.swift_version = '4.0'

  s.source       = { :git => "https://github.com/kballard/swift-tsao.git", :tag => "v#{s.version}" }
  s.source_files  = "Sources/*.swift"
end
