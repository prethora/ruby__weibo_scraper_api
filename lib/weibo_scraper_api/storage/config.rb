require 'fileutils'
require 'yaml'

class WSAPI
    module Storage
        class Config
            attr_accessor :data_dir
            attr_accessor :user_agent
            attr_accessor :config_path

            def initialize(config_path = nil)
                @data_dir = ""
                @user_agent = ""
                ENV["WSAPI_CONFIG_PATH"] = nil if ENV["WSAPI_CONFIG_PATH"].is_a?(String) && ENV["WSAPI_CONFIG_PATH"].strip==""
                @config_path = File.expand_path(config_path || ENV["WSAPI_CONFIG_PATH"] || "~/.wsapi/config.yaml")

                if File.exist? @config_path
                    raise StandardError.new("the config path refers to a directory but should refer to a file") if Dir.exist? @config_path
                else
                    dir_path = File.dirname(@config_path)
                    begin
                        FileUtils.mkdir_p dir_path
                    rescue
                        raise StandardError.new("the config path is invalid - unable to create the containing directory")
                    end

                    begin
                        File.open(@config_path,"w") { |file| file.write(default_config.to_yaml) }
                    rescue
                        raise StandardError.new("the config path is invalid - unable to write file to disk")
                    end
                end

                content = ""
                begin
                    content = File.read(@config_path)
                rescue
                    raise StandardError.new("the config path is invalid - unable to read file from disk")
                end

                values = {}
                begin
                    values = YAML.load(content)
                rescue => e
                    raise StandardError.new("config file is invalid - unable to parse YAML content with error: #{e.message}")
                end

                @data_dir = values["data_dir"]
                @user_agent = values["user_agent"]

                validate
            end 
                        
            def data_path
                File.expand_path(@data_dir,File.dirname(@config_path))
            end
            
            def get_data
                Data.new data_path
            end

            def default_config
                {
                    "data_dir" => "./data",
                    "user_agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36"
                }
            end

            def validate
                dc = default_config
                @data_dir = dc["data_dir"] if @data_dir.nil?
                @user_agent = dc["user_agent"] if @user_agent.nil?
                
                raise StandardError.new("config file is invalid - data_dir is expected to be a non-empty string") if !@data_dir.is_a?(String) || @data_dir.empty?
                raise StandardError.new("config file is invalid - user_agent is expected to be a non-empty string") if !@user_agent.is_a?(String) || @user_agent.empty?
            end

            def save
                begin
                    File.open(@config_path,"w") { |file| file.write(self.to_s) }
                rescue
                    raise StandardError.new("the config path is invalid - unable to write file to disk")
                end
            end

            def to_s
                {
                    "data_dir" => @data_dir,
                    "user_agent" => @user_agent
                }.to_yaml                
            end
        end
    end
end