#
# Be sure to run `pod lib lint GLNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '2.4.0'
  s.summary          = 'Just Simple Networking .by liguoliang.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'A simple of Networking.
  History Version:
    * 2.4.0
        move to github and public
    * 2.2.0
        Refactoring Structure use subspecs
    * 2.1.1
        fix: methodName for head
        opt: rename supJsonReq to isJsonParams , wipe warning
    * 2.1.0
        add GraphQL support
    * 2.0.0
        move from Github to Private GitLab Server && pod update, add response header
    * 1.1.4
        fix online status only invoke once, fix to invoke at check NetStatus time
    * 1.1.3
        fix Logic in No Net & No CacheData --> return NetFailed
    * 1.1.2
        remove JSONString(config.head) from  MD5 rule
    * 1.1.1
        detail with upload Request
    * 1.1.0
        add customList for cache
    '
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |ext|
    ext.source_files = 'GLNetworking/Classes/**/*.{h,m}'
    ext.frameworks = 'SystemConfiguration'
    ext.dependency 'AFNetworking', '3.2.0'
  end
  
  s.subspec 'Cache' do |ext|
    ext.source_files = 'GLNetworking/Cache/**/*.{h,m}'
    ext.dependency 'GLNetworking/Core'
  end
  
  s.subspec 'GraphQL' do |ext|
    ext.source_files = 'GLNetworking/Classes/**/*.{h,m}'
    ext.dependency 'GLNetworking/Core'
    ext.dependency 'YYModel', '1.0.4'
  end
  
end
