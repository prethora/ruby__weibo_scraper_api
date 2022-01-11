require "weibo_scraper_api"
require "weibo_scraper_api/cli/commands"

class WSAPI
    module CLI
        def self.run            
            begin
                WSAPI::CLI::Commands::Root.new.run ARGV
            rescue => e
                puts "error: #{e.message}"
            end
        end
    end
end