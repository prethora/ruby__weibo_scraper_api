require 'fileutils'
require 'date'

class WSAPI
    module Util
        module Storage
            class ConcurrentFile
                attr_accessor :file_path

                def initialize(file_path)
                    @file_path = File.expand_path(file_path)
                    begin
                        FileUtils.mkdir_p(@file_path)
                    rescue
                        raise StandardError("unable to create concurrent file '#{@file_path}', could not create containing directory'")
                    end                    
                end

                def write(value)
                    temp_file_path = get_temp_file_path
                    begin
                        File.open(temp_file_path,"w") { |file| file.write(value) }
                    rescue
                        raise StandardError("unable to create concurrent temp file '#{temp_file_path}', could not write to disk'")
                    end

                    content_file_path = get_current_content_file_path
                    version = content_file_path.split(".")[0]

                    begin
                        FileUtils.mv(temp_file_path,content_file_path)
                    rescue
                        raise StandardError("unable to move concurrent temp file '#{temp_file_path}, could not write to disk'")
                    end
                end

                private 

                def get_temp_file_path
                    while File.exist? (temp_file_path=File.join(@file_path,WSAPI::Util::String.gen_random_key)) do; end
                    temp_file_path
                end

                def get_current_content_file_path
                    timestamp = DateTime.now.strftime('%Q')
                    File.join(@file_path,"#{timestamp}.content")
                end
            end
        end
    end
end