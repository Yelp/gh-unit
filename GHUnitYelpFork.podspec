Pod::Spec.new do |s|
  s.name         = "GHUnitYelpFork"
  s.version      = "1.1.0"
  s.summary      = "GHUnit is a test framework for Mac OS X and iOS. It can be used standalone or with other testing frameworks like SenTestingKit or GTM."
  s.homepage     = "http://github.com/Yelp/gh-unit"
  s.license      = "MIT"
  s.author       = "Yelp"
  s.source       = { :git => 'https://github.com/Yelp/gh-unit.git', :tag => 'v' + s.version.to_s }  
  s.requires_arc = true
  s.header_dir   = "GHUnit"

  s.weak_framework = "UIKit"

  s.platform = :ios
  s.ios.deployment_target = "6.0"

  s.public_header_files = "Classes/**/*.h", "Classes-iOS/**/*.h"
  s.source_files = "Classes/**/*.{h,m}", "Classes-iOS/**/*.{h,m}", "Libraries/GTM/**/*.{h,m}"
end
