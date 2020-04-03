#
# Be sure to run `pod lib lint GLNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '2.5.1'
  s.summary          = 'Just Simple Networking .by liguoliang.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'A simple of Networking. by liguoliang 36617161@qq.com'
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |ext|
    ext.source_files = 'GLNetworking/Classes/Core/**/*.{h,m}'
    ext.frameworks = 'SystemConfiguration'
    ext.dependency 'AFNetworking'
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
