#
# Be sure to run `pod lib lint GLNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '2.6.2'
  s.summary          = '基于AFN3封装，采用链式方式，极大的增强了易用性和便捷性；并引入了请求优先级策略，优化输出'

  s.description      = '基于AFN3封装，采用链式方式，极大的增强了易用性和便捷性；并引入了请求优先级策略，优化输出'
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |ext|
    ext.source_files = 'GLNetworking/Classes/Core/**/*.{h,m}'
    ext.frameworks = 'SystemConfiguration'
    ext.dependency 'AFNetworking', '<4.0.0'
  end
  
  s.subspec 'Cache' do |ext|
    ext.source_files = 'GLNetworking/Classes/Cache/**/*.{h,m}'
    ext.dependency 'GLNetworking/Core'
  end
  
  s.subspec 'GraphQL' do |ext|
    ext.source_files = 'GLNetworking/Classes/GraphQL/**/*.{h,m}'
    ext.dependency 'GLNetworking/Core'
    ext.dependency 'YYModel'
  end
  
end
