Pod::Spec.new do |s|  
    s.name              = 'HealbeSDK'
    s.version           = '0.2.0'
    s.summary           = 'HealbeSDK'
    s.homepage          = 'https://healbe.com/eu/dev/'

    s.author            = { 'Name' => 'Healbe' }
    s.license           = { :type => 'CUSTOM', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :git => 'https://github.com/dkniss/sdk-test.git' }

    s.ios.deployment_target = '10.0'
    s.ios.vendored_frameworks = 'HealbeSDK.xcframework'
    s.preserve_paths = 'HealbeSDK.xcframework'
end  