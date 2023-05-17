Pod::Spec.new do |s|  
    s.name              = 'HealbeSDK'
    s.version           = '1.2.99'
    s.summary           = 'HealbeSDK'
    s.homepage          = 'https://healbe.com/eu/dev/'

    s.author            = { 'Name' => 'Healbe' }
    s.license           = { :type => 'CUSTOM', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :git => 'https://bitbucket.org/Healbe/healbe-public-ios-sdk.git' }

    s.ios.deployment_target = '12.0'
    s.ios.vendored_frameworks = 'HealbeSDK.framework'

    s.pod_target_xcconfig = {
    	'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end  