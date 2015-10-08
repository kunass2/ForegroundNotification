#
# Be sure to run `pod lib lint BSForegroundNotification.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BSForegroundNotification"
  s.version          = "0.1.1"
  s.summary          = "Present your custom iOS 8 and iOS 9 notification alert when app is in foreground mode."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "If you need present notification that looks like a native notifaction in iOS 8 or 9 with custom actions including textfield while app is in foreground mode... this framework is for you:-) Simple and straightforward in use."

  s.homepage         = "https://github.com/kunass2/BSForegroundNotification"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Bartłomiej Semańczyk" => "bartekss2@icloud.com" }
  s.source           = { :git => "https://github.com/kunass2/BSForegroundNotification.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.2'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'BSForegroundNotification' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AVFoundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
