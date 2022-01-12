require "bundler/setup"
require "rake"
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "weibo_scraper_api/version"

task :gem => :build
task :build do
    command = "mkdir -p dist/gems"
    system "echo '$' #{command}"
    system command
    system "echo"
    command = "gem build weibo_scraper_api.gemspec -o dist/gems/weibo_scraper_api-#{WSAPI::VERSION}.gem"
    system "echo '$' #{command}"
    system command
    system "echo"
    command = "gem build weibo_scraper_api_cli.gemspec -o dist/gems/weibo_scraper_api_cli-#{WSAPI::VERSION}.gem"
    system "echo '$' #{command}"
    system command
end