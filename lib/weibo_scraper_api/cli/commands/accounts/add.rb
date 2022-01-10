require 'weibo_scraper_api/cli/commands/base'

class WSAPI
    module CLI
        module Commands
            class Accounts
                class Add < Base
                    def run(argv)
                        return show_help if argv.length==1 && ["-h","--help"].include?(argv[0])

                        name = ""
                        options = {}
                        begin
                            OptionParser.new do |opt|
                                add_config_option opt,options
                            end.parse! argv
                            
                            raise StandardError.new("expecting a single argument (name)") if argv.length!=1

                            name = argv[0].strip
                            raise StandardError.new("expecting argument name to be a non-empty string") if name.empty?
                            raise StandardError.new("invalid name, can only contain: a-z A-Z 0-9 . _ and -") if (/^[a-zA-Z0-9\._-]+$/ =~ name).nil?
                        rescue => e
                            return output_usage_error e.message
                        end                        

                        begin
                            config = WSAPI::Storage::Config.new(options["config-path"])
                            data = config.get_data
                            return if data.get_accounts.include?(name) && !confirm_overwrite(name)

                            sm = WSAPI::Storage::SessionManager.new(config)
                            account_path = sm.add_account(name)
                            
                            puts
                            puts "------------------------------------------"
                            puts bright("Account session written to:")
                            puts "#{account_path}"
                            puts "------------------------------------------"
                            puts
                        rescue => e
                            puts "error: #{e.message}"
                        end
                    end

                    def confirm_overwrite(name)
                        $stdout.sync = true
                        print "#{bright("Account '#{name}' already exists, do you wish to overwrite it?")} (y/N): "
                        yes = STDIN.gets.chomp.downcase.strip=="y"
                        puts if yes
                        yes
                    end

                    def description
                        "Add a new account (or overwrite an existing one)"
                    end

                    def usage
                        %Q{
USAGE
  wsapi accounts add <name> [options]

ARGUMENTS
  name         an identifier to reference the account being added (or overwriten)
               can only contain: a-z A-Z 0-9 . _ and -

OPTIONS
  -h|--help    print this help page  
                        }.strip                
                    end
                end
            end
        end
    end
end