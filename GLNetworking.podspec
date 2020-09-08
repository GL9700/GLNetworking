#
# Be sure to run `pod lib lint GLFTest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNetworking'
  s.version          = '3.0.0'
  s.summary          = '基于GLNetworking进行的Framework化'

  s.description      = '采用链式方式，极大的增强了易用性和便捷性；并引入了请求优先级策略，优化输出.'
  s.homepage         = 'https://github.com/GL9700/GLNetworking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liguoliang' => '36617161@qq.com' }
  s.source           = { :git => 'https://github.com/GL9700/GLNetworking.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.frameworks = 'SystemConfiguration'

  if ENV['debug']
    s.vendored_frameworks = 'Framework/debug/GLNetworking.framework'
  else
    s.vendored_frameworks = 'Framework/release/GLNetworking.framework'
  end
  
end
