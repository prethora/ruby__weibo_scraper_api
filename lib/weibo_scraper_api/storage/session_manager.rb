class WSAPI
    module Storage
        class SessionManager
            def initialize(config)
                @config = config
                @data = config.get_data
                @session_cache = {}
            end

            def add_account(name)
                account_path = @data.get_account_path(name)
                session = WSAPI::API::Session.new
                session.login
                cf = WSAPI::Util::Storage::ConcurrentFile.new(account_path)
                cf.write(session.to_yaml)

                account_path
            end

            def get_session(name,renewFrom: nil)
                account_path = @data.get_account_path(name)
                raise StandardError("account '#{name}' not found") if !WSAPI::Util::Storage::ConcurrentFile.concurrent_file? account_path

                cf = WSAPI::Util::Storage::ConcurrentFile.new(account_path)
                version,file_path = cf.info

                return get_renewed_session(name,cf,file_path) if renewFrom==version

                return @session_cache[name] if @session_cache.key?(name) && @session_cache[name][0]==version

                session = WSAPI::API::Session.new
                session.load file_path

                @session_cache[name] = [version,session]
            end

            private

            def get_renewed_session(name,cf,file_path)
                session = WSAPI::API::Session.new
                session.load file_path
                session.renew
                cf.write(session.to_yaml)
                version,_ = cf.info

                @session_cache[name] = [version,session]
            end
        end
    end
end