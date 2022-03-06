#
# Be sure to run `pod lib lint SimpleApi.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SimpleApi'
  s.version          = '0.2.0'
  s.summary          = 'SimpleApi handles api calls and object parsing with minimum work'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
					SimpleApi handles api calls and object parsing with minimum work
                       DESC

  s.homepage         = 'https://github.com/kkubkko/SimpleApi'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kkubkko' => 'kkubkko@gmail.com' }
  s.source           = { :git => 'https://github.com/kkubkko/SimpleApi.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.3'

  s.source_files = 'SimpleApi/Classes/**/*'
  s.source_files = 'SimpleApi/Classes/*.{swift}'

  s.frameworks = 'Foundation'

  s.dependency 'RealmSwift'
  s.dependency 'ObjectMapper+Realm'
  s.dependency 'AlamofireObjectMapper'
  s.dependency 'Alamofire'
  s.dependency 'ReachabilitySwift'
  
  # s.resource_bundles = {
  #   'SimpleApi' => ['SimpleApi/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
