require 'rainbow'
require 'optparse'
require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class Configure < Base
                def run(argv)
                    cf = WSAPI::Util::Storage::ConcurrentFile.new("/home/mecrogenesis/Organizations/co.prethora/@ruby/weibo_scraper_api/cfile_test")
                    p cf.get_current_content_file_path

                    return
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

                        caption = bright("keep_alive_interval_days")
                        print "#{caption} (#{config.keep_alive_interval_days}): "
                        keep_alive_interval_days = STDIN.gets.chomp
                        keep_alive_interval_days = config.keep_alive_interval_days if keep_alive_interval_days==""
                        config.keep_alive_interval_days = keep_alive_interval_days.to_f

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