#
# Be sure to run `pod lib lint GLNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '1.1.0'
  s.summary          = 'Just Networking.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'A simple of Networking.
    1.1.0 for cache
    0.2.2 add function : download allow resume use [.supportResume(YES)] , default is NO;
    0.2.4 add PUT DELETE request Method;
    0.2.5 add custom body format in protocal use requestJSONSerializer
    0.2.7 fix timeout not valid [bug has in 0.2.5 ~ 0.2.6]
    '
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'GLNetworking/Classes/**/*'
  
  # s.resource_bundles = {
  #   'GLNetworking' => ['GLNetworking/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'AFNetworking', '3.2.1'
#   s.dependency 'MMKV', '1.0.17'
end
