Pod::Spec.new do |s|  
    s.name              = 'HealbeSDK'
    s.version           = '1.3.46'
    s.summary           = 'HealbeSDK'
    s.homepage          = 'https://healbe.com/eu/dev/'

    s.author            = { 'Name' => 'Healbe' }
    s.license           = { :type => 'CUSTOM', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :git => 'https://github.com/dkniss/sdk-test.git' }

    s.ios.deployment_target = '12.0'
    s.ios.vendored_frameworks = 'HealbeSDK.xcframework'
    s.preserve_paths = 'HealbeSDK.xcframework'

    s.pod_target_xcconfig = {
    	'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end  