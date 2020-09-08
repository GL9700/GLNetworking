#
# Be sure to run `pod lib lint GLFTest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '1.0.0'
  s.summary          = '本地Demo'

  # s.description      = '本地demo使用'
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.source_files = 'Classes/**/*'

  s.ios.deployment_target = '9.0'
  s.frameworks = 'SystemConfiguration'
  s.dependency 'AFNetworking'
  s.dependency 'YYModel'
  
end
