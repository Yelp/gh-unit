Pod::Spec.new do |s|
  s.name         = "GHUnit"
  s.version      = "1.0.0"
  s.summary      = "GHUnit is a test framework for Mac OS X and iOS. It can be used standalone or with other testing frameworks like SenTestingKit or GTM."
  s.homepage     = "http://github.com/Yelp/gh-unit"
  s.license      = "MIT"
  s.author       = "Yelp"
  s.source       = { :git => 'https://github.com/Yelp/gh-kit', :tag => 'v1.0.0' }  
  s.requires_arc = true

  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.7"

  s.ios.source_files = "Classes/**/*.{h,m}", "Classes-iOS/**/*.{h,m}", "Libraries/GTM/**/*.{h,m}"
  s.osx.source_files = "Classes/**/*.{h,m}", "Classes-MacOSX/**/*.{h,m}", "Libraries/GTM/**/*.{h,m}"
end
