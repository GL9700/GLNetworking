#
# Be sure to run `pod lib lint WDNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '2.8.0'
  s.summary          = '极简 & 灵活 & 稳定 & 安全的iOS Objective-C网络请求库'
  s.description      = <<-DESC
    - 极简：使用仅一行语句，即可发送网络请求。
    - 灵活：采用链式结构进行配置，且在请求前可修改已确定的任何项
    - 稳定：针对不同的网络环境做了测试，且收到的内容可进行手动修改和配置，可更改为不同形态。
    - 安全：可以在网络请求前进行参数的加密，相应的使用预设的内容也可以做相同的解密。设置不同的加解密方式
                       DESC

  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  
  s.subspec 'Core' do |ext|
    ext.source_files = 'GLNetworking/Classes/Core/**/*.{h,m}'
    ext.frameworks = 'SystemConfiguration'
    ext.dependency 'AFNetworking','>= 4.0.0'
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
