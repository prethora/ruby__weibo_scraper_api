require 'optparse'
require 'weibo_scraper_api/cli/commands/base'
require 'json'
require 'stringio'

class WSAPI
    module CLI
        module Commands
            class Configure < Base
                def run(argv)     
                    wsapi = WSAPI.new(account_name: "bob")
                    p wsapi.fans(wsapi.my_uid)
                    return  
                    return show_help if argv.length==1 && ["-h","--help"].include?(argv[0])

                    options = {}
                    begin
                        OptionParser.new do |opt|
                            add_config_option opt,options
                            opt.on("-p","--print",TrueClass) { |o| options["print"] = o }
                        end.parse! argv							

                        raise ArgumentError.new("unexpected argument: #{argv[0]}") if !argv.empty?
                    rescue => e
                        return output_usage_error e.message
                    end

                    begin
                        config = WSAPI::Storage::Config.new(options["config-path"])

                        return puts config if options["print"]

                        $stdout.sync = true

                        caption = bright("data_dir")
                        print "#{caption} (#{config.data_dir}): "
                        data_dir = STDIN.gets.chomp
                        data_dir = config.data_dir if data_dir==""
                        config.data_dir = data_dir

                        caption = bright("user_agent")
                        print "#{caption} (#{config.user_agent})\n: "
                        user_agent = STDIN.gets.chomp
                        user_agent = config.user_agent if user_agent==""
                        config.user_agent = user_agent

                        while true do
                            caption = bright("request_timeout_seconds")
                            print "#{caption} (#{config.request_timeout_seconds}): "
                            request_timeout_seconds = STDIN.gets.chomp
                            request_timeout_seconds = config.request_timeout_seconds.to_s if request_timeout_seconds==""
                            request_timeout_seconds.strip!
                            if (/^[0-9]+(?:\.[0-9]+)?$/=~request_timeout_seconds)==0 && request_timeout_seconds.to_f>=5
                                config.request_timeout_seconds = request_timeout_seconds.to_f
                                break
                            else
                                puts "error: invalid input, expecting a number greater or equal to 5"
                            end                            
                        end

                        while true do
                            caption = bright("request_retries")
                            print "#{caption} (#{config.request_retries}): "
                            request_retries = STDIN.gets.chomp
                            request_retries = config.request_retries.to_s if request_retries==""
                            request_retries.strip!
                            if (/^[0-9]+$/=~request_retries)==0
                                config.request_retries = request_retries.to_i
                                break
                            else
                                puts "error: invalid input, expecting a non-negative integer"
                            end                            
                        end

                        puts

                        begin
                            config.validate
                        rescue => e
                            raise ArgumentError.new(e.message.split(" - ")[1..-1].join(" - "))
                        end

                        config.save

                        puts "------------------------------------------"
                        puts bright("Configuration written to:")
                        puts "#{config.config_path}"
                        puts "------------------------------------------"
                        puts

                        puts config
                    rescue => e
                        puts "error: #{e.message}"
                    end                    
                end

                def print_config

                end

                def description
                    "Configure the API data directory and other values"
                end

                def usage
                    %Q{
USAGE
  wsapi configure [options]
  
OPTIONS
  -p|--print    print the current configuration instead of editing it
  -h|--help     show this help page
                    }.strip                
                end
            end
        end
    end
end