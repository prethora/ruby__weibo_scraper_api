require "weibo_scraper_api/api"
require "weibo_scraper_api/storage"
require "weibo_scraper_api/util"
require "weibo_scraper_api/exceptions"
require 'stringio'
require 'logger'

# The main API class which provides an interface to the weibo.com data.
class WSAPI
    # Returns a new instance of WSAPI.
    #
    # @param [String] config_path optionally explicitly provide the path to the configuration file. If not provided, defaults to +~/.wsapi/config.yaml+ or the value of the environment variable +WSAPI_CONFIG_PATH+, if set.
    # @param [String] account_name optionally specify which account to use by default for all method calls. If not provided, the account must be selected on each method call.
    def initialize(config_path: nil,account_name: nil)
        @account_name = account_name
        @config = WSAPI::Storage::Config.new(config_path)
        @config_data = @config.get_data
        @sm = WSAPI::Storage::SessionManager.new(@config)
        yield self if block_given?
    end

    # Returns the +uid+ of the selected account
    #
    # @param [String] account_name specify which account to use. Supersedes the +account_name+ provided to the constructor.
    # @return [String] the +uid+ of the selected account
    def my_uid(account_name: nil)
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        version,session = @sm.get_session account_name
        session.internal_uid
    end

    # Returns an unprocessed aggregation of the +profile/info+ and +profile/detail+ weibo.com API points for a specific user.
    #
    # @param [String|Integer] uid a +String+ or +Integer+ representation of the user's +uid+.
    # @param [String] account_name specify which account to use. Supersedes the +account_name+ provided to the constructor.
    # @return [Hash] +{'info' => ...,'detail' => ...}+
    def profile(uid,account_name: nil)
        strio = StringIO.new
        logger = Logger.new(strio)
        strio_info = StringIO.new
        logger_info = Logger.new(strio_info)
        strio_detail = StringIO.new
        logger_detail = Logger.new(strio_detail)        

        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")

        logger.info("WSAPI#profile: uid(#{uid}) account_name(#{account_name})")

        begin                        
            version,session = @sm.get_session account_name
            conn = session.conn

            for i in 1..2 do
                r_info,r_detail = [
                    Thread.new { request(conn,uid,"https://weibo.com/ajax/profile/info?uid=#{uid}","data",logger: logger_info) },
                    Thread.new { request(conn,uid,"https://weibo.com/ajax/profile/detail?uid=#{uid}","data",logger: logger_detail) }
                ].map(&:value)
                                
                raise WSAPI::Exceptions::UserNotFound.new(uid) if r_info["type"]=="error" && r_info["message"]=="USER_NOT_FOUND"
                raise WSAPI::Exceptions::UnknownResponseStatus.new(r_info["extra"]) if r_info["type"]=="error" && r_info["message"]=="UNKNOWN_RESPONSE_STATUS"
                raise WSAPI::Exceptions::UnknownResponseBody.new(r_info["extra"]) if r_info["type"]=="error" && r_info["message"]=="UNKNOWN_RESPONSE_BODY"
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00030") if r_info["type"]=="error" && r_info["message"]=="INVALID_JSON"      
                raise WSAPI::Exceptions::UnknownResponseStatus.new(r_detail["extra"]) if r_detail["type"]=="error" && r_detail["message"]=="UNKNOWN_RESPONSE_STATUS"
                raise WSAPI::Exceptions::UnknownResponseBody.new(r_detail["extra"]) if r_detail["type"]=="error" && r_detail["message"]=="UNKNOWN_RESPONSE_BODY"
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00031") if r_detail["type"]=="error" && r_detail["message"]=="INVALID_JSON"
                
                if is_response_stale?(r_info) || is_response_stale?(r_detail)
                    version,session = @sm.get_session(account_name,renewFrom: version,logger: logger)
                    conn = session.conn
                else
                    ret = {"info" => r_info["data"]["data"],"detail" => r_detail["data"]["data"]}
                    return yield ret if block_given?
                    return ret
                end
            end

            raise WSAPI::Exceptions::Unexpected.new("UNEXP00032")
        rescue => e            
            logger_detail.error e.message
            logger_detail.error e.backtrace.join("\n")
            log_content = [strio.string,strio_info.string,strio_detail.string].join("\n")            
            @config.get_log_data.create_log e,"WSAPI.profile",log_content
            raise
        end
    end

    # Returns one page of the unprocessed output of the +friendships/friends+ weibo.com API point for a specific user, with query paramers +relate=fans+ and +type=fans+ set.
    #
    # @param [String|Integer] uid a +String+ or +Integer+ representation of the user's +uid+.
    # @param [Integer] page the page number to request.
    # @param [String] account_name specify which account to use. Supersedes the +account_name+ provided to the constructor.
    # @return [Hash] +{'users' => [...],'total_number' => ...,'previous_cursor' => ...,'next_cursor' => ...}+
    def fans(uid,page = 1,account_name: nil)
        strio = StringIO.new
        logger = Logger.new(strio)

        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        page = WSAPI::Util::Validations::Integer.positive_integer?(page,"page")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        logger.info("WSAPI#fans: uid(#{uid}) page(#{page}) account_name(#{account_name})")

        begin
            version,session = @sm.get_session account_name
            conn = session.conn

            for i in 1..2 do
                response = request(conn,uid,"https://weibo.com/ajax/friendships/friends?relate=fans&page=#{page}&uid=#{uid}&type=fans","users",logger: logger)
                
                raise WSAPI::Exceptions::UserNotFound.new(uid) if response["type"]=="error" && response["message"]=="USER_NOT_FOUND"
                raise WSAPI::Exceptions::UnknownResponseStatus.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_STATUS"
                raise WSAPI::Exceptions::UnknownResponseBody.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_BODY"
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00033")  if response["type"]=="error" && response["message"]=="INVALID_JSON"                
                return {"users" => [],"total_number" => 0,"private" => true} if response["type"]=="error" && response["message"]=="ACCOUNT_PRIVATE"
                
                if is_response_stale?(response)
                    version,session = @sm.get_session(account_name,renewFrom: version,logger: logger)
                    conn = session.conn
                else
                    response["data"].delete "ok"
                    ret = response["data"]
                    return yield ret if block_given?
                    return ret
                end
            end

            raise WSAPI::Exceptions::Unexpected.new("UNEXP00034")
        rescue => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            @config.get_log_data.create_log e,"WSAPI.fans",strio.string
            raise
        end
    end

    # Returns one page of the unprocessed output of the +friendships/friends+ weibo.com API point for a specific user.
    #
    # @param [String|Integer] uid a +String+ or +Integer+ representation of the user's +uid+.
    # @param [Integer] page the page number to request.
    # @param [String] account_name specify which account to use. Supersedes the +account_name+ provided to the constructor.
    # @return [Hash] +{'users' => [...],'total_number' => ...,'previous_cursor' => ...,'next_cursor' => ...}+
    def friends(uid,page = 1,account_name: nil)
        strio = StringIO.new
        logger = Logger.new(strio)

        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        page = WSAPI::Util::Validations::Integer.positive_integer?(page,"page")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        logger.info("WSAPI#friends: uid(#{uid}) page(#{page}) account_name(#{account_name})")

        begin
            version,session = @sm.get_session account_name
            conn = session.conn

            for i in 1..2 do
                response = request(conn,uid,"https://weibo.com/ajax/friendships/friends?page=#{page}&uid=#{uid}","users",logger: logger)
                
                raise WSAPI::Exceptions::UserNotFound.new(uid) if response["type"]=="error" && response["message"]=="USER_NOT_FOUND"
                raise WSAPI::Exceptions::UnknownResponseStatus.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_STATUS"
                raise WSAPI::Exceptions::UnknownResponseBody.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_BODY"
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00035") if response["type"]=="error" && response["message"]=="INVALID_JSON"
                return {"users" => [],"total_number" => 0,"private" => true} if response["type"]=="error" && response["message"]=="ACCOUNT_PRIVATE"
                
                if is_response_stale?(response)
                    version,session = @sm.get_session(account_name,renewFrom: version,logger: logger)
                    conn = session.conn
                else
                    response["data"].delete "ok"
                    ret = response["data"]
                    return yield ret if block_given?
                    return ret
                end
            end

            raise WSAPI::Exceptions::Unexpected.new("UNEXP00036")
        rescue => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            @config.get_log_data.create_log e,"WSAPI.friends",strio.string
            raise
        end
    end

    # Returns one page of the unprocessed output of the +statuses/mymblog+ weibo.com API point for a specific user.
    #
    # Note: when the last page is encountered, the +since_id+ field in the response is an empty string.
    #
    # @param [String|Integer] uid a +String+ or +Integer+ representation of the user's +uid+.
    # @param [String] since_id a value included in each response which should be provided here in order to request the next page. If not provided, the first page is requested.
    # @param [String] account_name specify which account to use. Supersedes the +account_name+ provided to the constructor.
    # @return [Hash] +{'list' => [...],'since_id' => ...}+
    def statuses(uid,since_id = nil,account_name: nil)
        strio = StringIO.new
        logger = Logger.new(strio)

        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        since_id = WSAPI::Util::Validations::String.matches?(since_id,/^[0-9]+kp[0-9]+$/,"since_id",optional: true)
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")

        logger.info("WSAPI#statuses: uid(#{uid}) since_id(#{since_id}) account_name(#{account_name})")

        prefix,page = since_id.nil? ? ["","1"] : /^([0-9]+)kp([0-9]+$)/.match(since_id).captures
        since_id_suffix = prefix.empty? ? "" : "&since_id=#{since_id}"
        url = "https://weibo.com/ajax/statuses/mymblog?uid=#{uid}&page=#{page}&feature=0#{since_id_suffix}"

        begin
            version,session = @sm.get_session account_name
            conn = session.conn

            for i in 1..2 do
                response = request(conn,uid,url,"data",logger: logger)
                
                raise WSAPI::Exceptions::UserNotFound.new(uid) if response["type"]=="error" && response["message"]=="USER_NOT_FOUND"
                raise WSAPI::Exceptions::UnknownResponseStatus.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_STATUS"
                raise WSAPI::Exceptions::UnknownResponseBody.new(response["extra"]) if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE_BODY"
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00037") if response["type"]=="error" && response["message"]=="INVALID_JSON"                
                
                if is_response_stale?(response)
                    version,session = @sm.get_session(account_name,renewFrom: version,logger: logger)
                    conn = session.conn
                else
                    ret = response["data"]["data"]
                    return yield ret if block_given?
                    return ret
                end            
            end

            raise WSAPI::Exceptions::Unexpected.new("UNEXP00038")
        rescue => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            @config.get_log_data.create_log e,"WSAPI.statuses",strio.string
            raise
        end
    end

    # Check all configured accounts for stale sessions and renew them.
    #
    # *Note*: Account sessions become stale 24 hours after they are created/renewed. The API automatically
    # renews them if they are found to have staled upon all request method calls, so you generally do not have to worry about stale sessions.
    # However, if you do not use (and thus renew) a session for a long period of time, it may become completely invalidated, in which case
    # you would have to add the account again using the CLI tool. (I have yet to actually experience this, I have been able to renew sessions even several weeks 
    # after no use - but I am assuming that after some period of time they would probably expire).
    #
    # *Recommended*: to be safe, it would be a good idea to run the +wsapi accounts keep_alive+ command (which calls this method) 
    # as a cron job say every 5 days, to make sure any accounts you have configured but do not use regularly stay alive indefinitely.
    # If you are using all accounts regularly though, this is unnecessary.
    #
    # @return [Array<String>] a list of account names for the accounts that were renewed.
    def keep_alive
        strio = StringIO.new
        logger = Logger.new(strio)

        logger.info("WSAPI#keep_alive")

        begin
            renewed = []
            data = @config.get_data
            data.get_accounts.each do |account_name|
                version,session = @sm.get_session account_name
                if !session.is_active?(logger: logger)
                    @sm.get_session(account_name,renewFrom: version,logger: logger)
                    renewed << account_name
                end
            end
            renewed
        rescue => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            @config.get_log_data.create_log e,"WSAPI.keep_alive",strio.string
            raise
        end
    end

    private 

    def is_response_stale?(response)
        response["type"]=="error" && response["message"]=="STALE_SESSION"
    end

    def request(conn,uid,url,key_check,logger: nil)
        headers = {"referer" => "https://weibo.com/u/#{uid}","accept" => "application/json, text/plain, */*"}
        response = conn.get(url,headers: headers,logger: logger);
        
        begin
            json_response = JSON.parse(response.body)
        rescue
            return {"type" => "error","message" => "INVALID_JSON"}
        end
                
        return {"type" => "error","message" => "USER_NOT_FOUND"} if response.status==400 && json_response["ok"]==0 && json_response["message"].is_a?(String) && json_response["message"].include?("(20003)")
        return {"type" => "error","message" => "UNKNOWN_RESPONSE_STATUS","extra" => {"status" => response.status,"body" => response.body}} if response.status!=200
        return {"type" => "error","message" => "STALE_SESSION"} if json_response["ok"]==-100 && json_response["url"].is_a?(String) && json_response["url"].include?("/login.php?")
        return {"type" => "success","data" => json_response} if json_response["ok"]==1 && !json_response[key_check].nil?
        return {"type" => "error","message" => "ACCOUNT_PRIVATE"} if json_response["ok"]==0 && json_response["statusCode"]==200 && json_response["relation_display"]==1
        return {"type" => "error","message" => "UNKNOWN_RESPONSE_BODY","extra" => {"status" => response.status,"body" => response.body}}
    end
end