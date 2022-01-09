require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class Accounts
                class List < Base
                    def run(argv)
                        return show_help if argv.length==1 && ["-h","--help"].include?(argv[0])

                        options = {}
                        begin
                            OptionParser.new do |opt|
                                add_config_option opt,options
                            end.parse! argv
                            
                            raise StandardError.new("unexpected argument: #{argv[0]}") if !argv.empty?
                        rescue => e
                            return output_usage_error e.message
                        end                        

                        begin
                            config = WSAPI::Storage::Config.new(options["config-path"])
                            puts config.get_data.get_accounts.sort
                        rescue => e
                            puts "error: #{e.message}"
                        end
                    end

                    def description
                        "List existing accounts"
                    end

                    def usage
                        %Q{
USAGE
  wsapi accounts ls [options]

OPTIONS
  -h|--help    show this help page
                        }.strip                
                    end
                end
            end
        end
    end
end