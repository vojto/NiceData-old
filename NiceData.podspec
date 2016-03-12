#
# Be sure to run `pod lib lint NiceData.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "NiceData"
  s.version          = "0.1.0"
  s.summary          = "Data layer abstraction that hides CoreData or Firebase for now"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "description here"

  s.homepage         = "https://github.com/vojto/NiceData"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Vojtech Rinik" => "vojto@rinik.net" }
  s.source           = { :git => "https://github.com/vojto/NiceData.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.requires_arc = true

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.11"

  s.source_files = ['Pod/Classes/Shared/**/*', 'Pod/Classes/Mac/**/*']
  
  s.dependency 'MagicalRecord'
  s.osx.dependency 'FirebaseOSX'
  s.ios.dependency 'Firebase'
end
