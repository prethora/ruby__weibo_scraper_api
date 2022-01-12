source "https://rubygems.org"

Dir["*.gemspec"].each do |gemspec_path|
  gem_name = gemspec_path.scan(/(.*)\.gemspec$/).flatten.first
  gemspec(:name => gem_name)
end

gem 'rake'