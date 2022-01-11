require 'weibo_scraper_api/cli/commands/base'
require 'weibo_scraper_api/version'

class WSAPI
    module CLI
        module Commands
            class Root < Base
                def initialize
                    @command_classes = {
						"accounts" => Accounts,
                        "configure" => Configure
					}
                end

                def run(argv)
                    return show_help if argv.empty? || (argv.length==1 && ["-h","--help"].include?(argv[0]))
                    return show_version if argv.length==1 && ["-v","--version"].include?(argv[0])                    
                    argv = argv[1..-1]+["-h"] if argv.length>1 && argv[0]=="help"

                    command_name = argv[0]

                    return output_usage_error("command '#{command_name}' does not exist") if !@command_classes.key? command_name

                    @command_classes[command_name].new.run(argv[1..-1])
                end

                def description
                    "Manage the unofficial Weibo Scraper API"                    
                end

                def usage
                    %Q{
USAGE
    wsapi <command> ...
    wsapi [options]

COMMANDS
    accounts            #{@command_classes["accounts"].new.lcase_description}
    configure           #{@command_classes["configure"].new.lcase_description}

OPTIONS
    -h|--help           print this help page
    -v|--version        print the cli version

GLOBAL OPTION
    The following option can be used on all executable commands

    -c|--config-path    the path to the WSAPI configuration file.
                        defaults to ~/.wsapi/config.yaml or the value of the
                        WSAPI_CONFIG_PATH environment variable, if set

                    }.strip                
                end

                def show_version
                    puts "version: #{WSAPI::VERSION}"
                end
            end
        end
    end
end