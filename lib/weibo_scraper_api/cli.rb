require "weibo_scraper_api"

class WSAPI
    class CLI
        def self.run
            begin
                session = WSAPI::API::Session.new
                # session.login
                # session.save "test_session.yaml"
                session.load "test_session.yaml"
                session.test
            rescue WSAPI::Exceptions::Unexpected => e
                p ["rescued",e.message]
            end
        end
    end
end