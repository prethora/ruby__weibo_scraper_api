$:.push File.expand_path("../lib", __FILE__)
require 'weibo_scraper_api/version'

Gem::Specification.new do |s|
  s.name        = 'weibo_scraper_api'
  s.version     = WSAPI::VERSION
  s.summary     = "An unofficial Weibo API"
  s.description = "An unofficial Weibo API"
  s.authors     = ["Dominique Adolphe"]
  s.email       = 'dominique.adolphe@gmail.com'
  s.files       = Dir.glob('lib/**/*')
  s.executables << "wsapi"
  s.add_runtime_dependency "bundler"
  s.add_runtime_dependency "faraday","~> 1.0"
  s.add_runtime_dependency "faraday-cookie_jar"
  s.add_runtime_dependency "faraday_middleware"
  s.add_runtime_dependency "http-cookie"
  s.add_runtime_dependency "rainbow"
  s.license       = 'MIT'
end