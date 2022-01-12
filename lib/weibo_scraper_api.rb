require "weibo_scraper_api/api"
require "weibo_scraper_api/storage"
require "weibo_scraper_api/util"
require "weibo_scraper_api/exceptions"

class WSAPI
    def initialize(config_path: nil,account_name: nil)
        @account_name = account_name
        @config = WSAPI::Storage::Config.new(config_path)
        @sm = WSAPI::Storage::SessionManager.new(@config)
        yield self if block_given?
    end

    def profile(uid,account_name: nil)
        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        version,session = @sm.get_session account_name
        conn = session.conn

        for i in 1..2 do
            r_info,r_detail = [
                Thread.new { request(conn,uid,"https://weibo.com/ajax/profile/info?uid=#{uid}","data") },
                Thread.new { request(conn,uid,"https://weibo.com/ajax/profile/detail?uid=#{uid}","data") }
            ].map(&:value)
            
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00030")  if r_info["type"]=="error" && r_info["message"]=="WRONG_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00031")  if r_info["type"]=="error" && r_info["message"]=="INVALID_JSON"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00032")  if r_info["type"]=="error" && r_info["message"]=="UNKNOWN_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00033")  if r_detail["type"]=="error" && r_detail["message"]=="WRONG_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00034")  if r_detail["type"]=="error" && r_detail["message"]=="INVALID_JSON"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00035")  if r_detail["type"]=="error" && r_detail["message"]=="UNKNOWN_RESPONSE"
            
            if is_response_stale?(r_info) || is_response_stale?(r_detail)
                version,session = @sm.get_session(account_name,renewFrom: version)
                conn = session.conn
            else
                return {"info" => r_info["data"]["data"],"detail" => r_detail["data"]["data"]}
            end
        end

        raise WSAPI::Exceptions::Unexpected.new("UNEXP00036")        
    end

    def fans(uid,page = 1,account_name: nil)
        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        page = WSAPI::Util::Validations::Integer.positive_integer?(page,"page")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        version,session = @sm.get_session account_name
        conn = session.conn

        for i in 1..2 do
            response = request(conn,uid,"https://weibo.com/ajax/friendships/friends?relate=fans&page=#{page}&uid=#{uid}&type=fans","users")
            
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00037")  if response["type"]=="error" && response["message"]=="WRONG_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00038")  if response["type"]=="error" && response["message"]=="INVALID_JSON"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00039")  if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE"
            return {"users" => [],"total_number" => 0,"private" => true} if response["type"]=="error" && response["message"]=="ACCOUNT_PRIVATE"
            
            if is_response_stale?(response)
                version,session = @sm.get_session(account_name,renewFrom: version)
                conn = session.conn
            else
                response["data"].delete "ok"
                return response["data"]
            end
        end

        raise WSAPI::Exceptions::Unexpected.new("UNEXP00040")
    end

    def friends(uid,page = 1,account_name: nil)
        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        page = WSAPI::Util::Validations::Integer.positive_integer?(page,"page")
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")
        
        version,session = @sm.get_session account_name
        conn = session.conn

        for i in 1..2 do
            response = request(conn,uid,"https://weibo.com/ajax/friendships/friends?page=#{page}&uid=#{uid}","users")
            
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00041") if response["type"]=="error" && response["message"]=="WRONG_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00042") if response["type"]=="error" && response["message"]=="INVALID_JSON"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00043") if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE"
            return {"users" => [],"total_number" => 0,"private" => true} if response["type"]=="error" && response["message"]=="ACCOUNT_PRIVATE"
            
            if is_response_stale?(response)
                version,session = @sm.get_session(account_name,renewFrom: version)
                conn = session.conn
            else
                response["data"].delete "ok"
                return response["data"]
            end
        end

        raise WSAPI::Exceptions::Unexpected.new("UNEXP00044")
    end

    def statuses(uid,since_id = nil,account_name: nil)
        uid = WSAPI::Util::Validations::String.positive_integer?(uid,"uid")
        since_id = WSAPI::Util::Validations::String.matches?(since_id,/^[0-9]+kp[0-9]+$/,"since_id",optional: true)
        account_name = WSAPI::Util::Validations::String.not_empty?(account_name || @account_name,"account_name")

        prefix,page = since_id.nil? ? ["","1"] : /^([0-9]+)kp([0-9]+$)/.match(since_id).captures
        since_id_suffix = prefix.empty? ? "" : "&since_id=#{since_id}"
        url = "https://weibo.com/ajax/statuses/mymblog?uid=#{uid}&page=#{page}&feature=0#{since_id_suffix}"

        version,session = @sm.get_session account_name
        conn = session.conn

        for i in 1..2 do
            response = request(conn,uid,url,"data")
            
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00045") if response["type"]=="error" && response["message"]=="WRONG_RESPONSE"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00046") if response["type"]=="error" && response["message"]=="INVALID_JSON"
            raise WSAPI::Exceptions::Unexpected.new("UNEXP00047") if response["type"]=="error" && response["message"]=="UNKNOWN_RESPONSE"
            
            if is_response_stale?(response)
                version,session = @sm.get_session(account_name,renewFrom: version)
                conn = session.conn
            else
                return response["data"]["data"]
            end            
        end

        raise WSAPI::Exceptions::Unexpected.new("UNEXP00048")
    end

    def keep_alive
        renewed = []
        data = @config.get_data
        data.get_accounts.each do |account_name|
            version,session = @sm.get_session account_name
            if !session.is_active?
                @sm.get_session(account_name,renewFrom: version)
                renewed << account_name
            end
        end
        renewed
    end

    private 

    def is_response_stale?(response)
        response["type"]=="error" && response["message"]=="STALE_SESSION"
    end

    def request(conn,uid,url,key_check)
        headers = {"referer" => "https://weibo.com/u/#{uid}","accept" => "application/json, text/plain, */*"}
        response = conn.get(url,headers: headers);
        return {"type" => "error","message" => "WRONG_RESPONSE"} if response.status!=200

        begin
            json_response = JSON.parse(response.body)
        rescue
            return {"type" => "error","message" => "INVALID_JSON"}
        end

        return {"type" => "error","message" => "STALE_SESSION"} if json_response["ok"]==-100 && json_response["url"].is_a?(String) && json_response["url"].include?("/login.php?")
        return {"type" => "success","data" => json_response} if json_response["ok"]==1 && !json_response[key_check].nil?
        # p ["unknown",json_response]
        return {"type" => "error","message" => "ACCOUNT_PRIVATE"} if json_response["ok"]==0 && json_response["statusCode"]==200 && json_response["relation_display"]==1
        return {"type" => "error","message" => "UNKNOWN_RESPONSE"}
    end
end