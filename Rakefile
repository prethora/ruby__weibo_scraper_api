require "bundler/setup"
require "rake"
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "weibo_scraper_api/version"

task :gem => :build
task :build do
    command = "mkdir -p dist/gems"
    puts "$ #{command}"
    system command
    puts
    command = "gem build weibo_scraper_api.gemspec -o dist/gems/weibo_scraper_api-#{WSAPI::VERSION}.gem"
    puts "$ #{command}"
    system command
    puts
    command = "gem build weibo_scraper_api_cli.gemspec -o dist/gems/weibo_scraper_api_cli-#{WSAPI::VERSION}.gem"
    puts "$ #{command}"
    system command
end

task "install-cli" do
    command = "gem install dist/gems/weibo_scraper_api_cli-#{WSAPI::VERSION}.gem"
    puts "$ #{command}"
    system command
end