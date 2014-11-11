Pod::Spec.new do |s|
    s.name = "PatternLock"
    s.version = "1.0.0"
    s.summary = "A simple but fully functional pattern lock sdk for iOS (similar to the android pattern lock"
    s.homepage = "http://github.com/yuanping/PatternLock"
    s.license = 'MIT'
    s.author = { "David Hart" => "david@hart-dev.com", "Yuan Ping" => "yp.xjgz@gmail.com" }
    s.source = { :git => "https://github.com/yuanping/PatternLock.git" }
    s.requires_arc = true
    s.ios.deployment_target = "5.0"
    s.source_files = 'SPLockScreen'
    s.public_header_files = 'SPLockScreen/**/*.h'
    s.frameworks = 'Foundation'
end