require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class Accounts
                class KeepAlive < Base
                    def run(argv)
                        return show_help if argv.length==1 && ["-h","--help"].include?(argv[0])

                        options = {}
                        begin
                            OptionParser.new do |opt|
                                add_config_option opt,options                                
                                opt.on("-q","--quiet",TrueClass) { |o| options["quiet"] = o }
                            end.parse! argv
                            
                            raise StandardError.new("unexpected argument: #{argv[0]}") if !argv.empty?
                        rescue => e
                            return output_usage_error e.message
                        end                        

                        quiet = options["quiet"]==true

                        begin
                            WSAPI.new(config_path: options["config-path"]) do |wsapi|
                                renewed = wsapi.keep_alive
                                if !quiet
                                    puts "No stale account sessions found" if renewed.empty?
                                    puts "The sessions for the following accounts were stale and have been renewed:\n\n#{renewed.join("\n")}" if !renewed.empty?
                                end
                            end
                        rescue => e
                            puts "error: #{e.message}"
                        end
                    end

                    def description
                        "Renew any stale account sessions"
                    end

                    def usage
                        %Q{
USAGE
  wsapi accounts keep_alive [options]  

OPTIONS
  -q|--quiet    suppress output
  -h|--help     show this help page
                        }.strip                
                    end
                end
            end
        end
    end
end