require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class KeepAlive < Base
                def run(argv)
                end

                def description
                    "this is the keepalive command"
                end

                def usage
                    %Q{
                    }.strip                
                end
            end
        end
    end
end