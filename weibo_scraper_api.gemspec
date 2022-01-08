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
  s.license       = 'MIT'
end