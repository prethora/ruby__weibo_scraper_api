require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class Accounts < Base
                def initialize
                    @command_classes = {
                        "add" => Add,
                        "ls" => List,
                        "keep_alive" => KeepAlive
                    }    
                end

                def run(argv)
                    return show_help if argv.empty? || (argv.length==1 && ["-h","--help"].include?(argv[0]))

                    command_name = argv[0]

                    return output_usage_error("command '#{command_name}' does not exist") if !@command_classes.key? command_name

                    @command_classes[command_name].new.run(argv[1..-1])
                end

                def description
                    "Manage multiple Weibo accounts to use with the API"
                end

                def usage
                    %Q{
USAGE
    wsapi accounts <command> ...
    wsapi accounts <option>
                    
COMMANDS
    add           #{@command_classes["add"].new.lcase_description}
    ls            #{@command_classes["ls"].new.lcase_description}
    keep_alive    #{@command_classes["keep_alive"].new.lcase_description}
                    
OPTIONS
    -h|--help    print this help page
                                        }.strip                
                end
            end
        end
    end
end