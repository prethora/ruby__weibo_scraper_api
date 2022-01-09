require "weibo_scraper_api"
require "weibo_scraper_api/cli/commands"

class WSAPI
    module CLI
        def self.run
            begin
                WSAPI::CLI::Commands::Root.new.run ARGV

                # session = WSAPI::API::Session.new
                # session.login
                # session.save "test_session.yaml"
                # session.load "test_session.yaml"                
                # session.load "/home/mecrogenesis/Organizations/co.prethora/@ruby/_weibo_scraper_api_setup/even_newer_cookies_jar"
                # p session.is_active?
                # session.renew
                # session.save "test_renewed_session.yaml"
                # p session.is_active?
                # session.load "test_renewed_session.yaml"
                # p session.is_active?
            rescue WSAPI::Exceptions::Unexpected => e
                p ["rescued",e.message]
            end
        end
    end
end