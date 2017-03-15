#
# Be sure to run `pod lib lint ForegroundNotification.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BSForegroundNotification"
  s.version          = "2.0.1"
  s.summary          = "Present your custom iOS 10 notification alert when app is in foreground mode."
  s.description      = "If you need present notification that looks like a native notifaction in iOS 10 with custom actions including textfield while app is in foreground mode... this framework is for you:-) Simple and straightforward in use."

  s.homepage         = "https://github.com/kunass2/ForegroundNotification"
  s.license          = 'MIT'
  s.author           = { "Bartłomiej Semańczyk" => "bartekss2@icloud.com" }
  s.source           = { :git => "https://github.com/kunass2/ForegroundNotification.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'ForegroundNotification/Classes/**/*'
  s.frameworks = 'UIKit', 'AVFoundation'

end
