require 'optparse'
require 'weibo_scraper_api/cli/commands/base'
require 'json'

class WSAPI
    module CLI
        module Commands
            class Configure < Base
                def run(argv)                    
                    # WSAPI.new(account_name: "stale") do |wsapi|
                    #     # p wsapi.keep_alive
                    #     p wsapi.profile 2125613987
                    #     # puts wsapi.fans(2125613987,"2").to_json
                    #     # puts wsapi.profile(5471534537).to_json
                    #     # puts wsapi.fans(5471534537).to_json
                    #     # puts wsapi.friends(5471534537).to_json
                    #     # p wsapi.friends 2125613987
                    #     # puts wsapi.statuses(2125613987,"4724034534640347kp6").to_json
                    # end

                    # fetcher = lambda do |uri,vv|
                    #     puts "Started fetching #{uri}"
                    #     # puts open(uri).read
                    #     puts "Stopped fetching #{uri}"
                    #     [uri,vv]
                    # end
                      
                    # thread1 = Thread.new("http://localhost:9292", "v1",&fetcher)
                    # thread2 = Thread.new("http://localhost:9293", "v2",&fetcher)
                      
                    # # thread1.join
                    # # thread2.join                    

                    # p [thread1.value,thread2.value]

                    # return
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

                        puts

                        begin
                            config.validate
                        rescue => e
                            raise StandardError.new(e.message.split(" - ")[1..-1].join(" - "))
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

                def description
                    "Configure the API data directory and other values"
                end

                def usage
                    %Q{
USAGE
  wsapi configure [options]
  
OPTIONS
  -h|--help    show this help page
                    }.strip                
                end
            end
        end
    end
end