require 'optparse'
require 'rainbow'

class WSAPI
    module CLI
        module Commands
            class Base
                def output_usage_error(message)
                    puts "error: #{message}\n\n#{usage}"
                end

                def show_help
                    puts "#{description}\n\n#{usage}"
                end

                def description
                    ""
                end

                def lcase_description
                    "#{description[0..0].downcase}#{description[1..-1]}"                    
                end

                def usage
                    ""
                end

                protected

                def add_config_option(opt,options)
                    opt.on("-c","--config-path CONFIGPATH") { |o| options["config-path"] = o }
                end

                def bright(str)
                    Rainbow(str).white.bright
                end
            end
        end
    end
end