#
# Be sure to run `pod lib lint GLNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '2.2.0'
  s.summary          = 'Just Simple Networking.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'A simple of Networking.
  History Version:
    > 2.0
      * 0 move from Github to Private GitLab Server && pod update, add response header
      * 1 add GraphQL support
        * 1 fix: methodName for head
        * 2 opt: rename supJsonReq to isJsonParams , wipe warning
      * 2 Refactoring Structure use subspecs

    > 1.1
      * 4 fix online status only invoke once, fix to invoke at check NetStatus time
    	* 3 fix Logic in No Net & No CacheData --> return NetFailed
    	* 2 remove JSONString(config.head) from  MD5 rule
        * 1 detail with upload Request
        * 0 add customList for cache
    > 0.2
        * 7 fix timeout not valid [bug has in 0.2.5 ~ 0.2.6]
        * 5 add custom body format in protocal use requestJSONSerializer
        * 4 add PUT DELETE request Method;
        * 2 add function : download allow resume use [.supportResume(YES)] , default is NO;
    '
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'GL9700' => '36617161@qq.com' }
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
