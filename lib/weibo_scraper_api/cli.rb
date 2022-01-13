require "weibo_scraper_api"
Dir[File.join(__dir__,"cli","**","*.rb")].each {|l| require l}

class WSAPI
    module CLI
        def self.run            
            begin
                WSAPI::CLI::Commands::Root.new.run ARGV
            rescue => e
                puts "error: #{e.message}"
                # raise
            end
        end
    end
end