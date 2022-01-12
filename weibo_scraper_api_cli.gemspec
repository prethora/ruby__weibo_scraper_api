$:.push File.expand_path("../lib", __FILE__)
require 'weibo_scraper_api/version'

Gem::Specification.new do |s|
  s.name        = 'weibo_scraper_api_cli'
  s.version     = WSAPI::VERSION
  s.summary     = "A command-line tool for an unofficial Weibo Scraper API"
  s.description = "A command-line tool for an unofficial Weibo API"
  s.authors     = ["Dominique Adolphe"]
  s.email       = 'dominique.adolphe@gmail.com'
  s.files       = Dir.glob('lib/**/*') + %W{Gemfile Gemfile.lock weibo_scraper_api_cli.gemspec}
  s.executables << "wsapi"
  s.add_runtime_dependency "faraday","~> 1.0"
  s.add_runtime_dependency "faraday-cookie_jar","~> 0.0"
  s.add_runtime_dependency "faraday_middleware","~> 1.2"
  s.add_runtime_dependency "http-cookie","~> 1.0"
  s.add_runtime_dependency "rainbow","~> 3.1"
  s.license       = 'Nonstandard'
  s.homepage     = "https://not-applicable.org"
end