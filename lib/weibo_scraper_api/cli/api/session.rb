require 'weibo_scraper_api'
require 'rainbow'
require 'json'

class WSAPI
    module API
        class Session
            def login
                puts Rainbow("Requesting QRCODE from the weibo website...").white.bright
                puts ""

                url = "https://weibo.com"
                response = @conn.get(url);
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00001","status: #{response.status}") if response.status!=200

                url = "https://login.sina.com.cn/sso/qrcode/image?entry=weibo&size=180&callback=STK_16416525441041"
                headers = {"referer" => "https://weibo.com/"}
                response = @conn.get(url,headers: headers);
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00002","status: #{response.status}") if response.status!=200                
                
                json_response_str = WSAPI::Util::String.simple_parse(response.body,"STK_16416525441041(",");")
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00003") if json_response_str.nil?
                
                json_response = JSON.parse(json_response_str)
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00004") if json_response["retcode"]!=20000000
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00005") if json_response["data"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00006") if json_response["data"]["qrid"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00007") if json_response["data"]["image"].nil?
                
                qrcode_id = json_response["data"]["qrid"]
                qrcode_url = "https:#{json_response["data"]["image"]}" 

                lines = [                    
                    Rainbow("Open the following link in a browser and scan the QRCODE from the Weibo mobile app:").white.bright,
                    "",
                    Rainbow(qrcode_url).underline,
                    "",
                    Rainbow("Once scanned, return to this prompt to continue. Awaiting scan...").white.bright
                ]
                puts lines.join("\n")

                alt = ""
                while true do 
                    url = "https://login.sina.com.cn/sso/qrcode/check?entry=weibo&qrid=#{qrcode_id}&callback=STK_16416586318723"
                    headers = {"referer" => "https://weibo.com/"}
                    response = @conn.get(url,headers: headers);
                    raise WSAPI::Exceptions::Unexpected.new("UNEXP00008","status: #{response.status}") if response.status!=200

                    json_response = WSAPI::Util::String.simple_parse(response.body,"STK_16416586318723(",");")
                    raise WSAPI::Exceptions::Unexpected.new("UNEXP00009") if json_response.nil?
                    json_response = JSON.parse(json_response)
                    if json_response["retcode"]==20000000 && !json_response["data"].nil? && !json_response["data"]["alt"].nil?
                        alt = json_response["data"]["alt"]
                        break
                    end

                    sleep 5                    
                end   

                puts ""
                puts Rainbow("Creating session...").white.bright

                url = "https://login.sina.com.cn/sso/login.php?entry=weibo&returntype=TEXT&crossdomain=1&cdult=3&domain=weibo.com&alt=#{CGI.escape(alt)}&savestate=30&callback=STK_164165863187215"
                headers = {"referer" => "https://weibo.com/"}
                response = @conn.get(url,headers: headers);
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00010","status: #{response.status}") if response.status!=200

                json_response = WSAPI::Util::String.simple_parse(response.body,"STK_164165863187215(",");")
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00011") if json_response.nil?
                json_response = JSON.parse(json_response)
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00012") if json_response["crossDomainUrlList"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00013") if json_response["crossDomainUrlList"].empty?

                uid = 0

                json_response["crossDomainUrlList"].each do |url|
                    headers = {"referer" => "https://weibo.com/"}
                    response = @conn.get(url,headers: headers);        
                    raise WSAPI::Exceptions::Unexpected.new("UNEXP00014","status: #{response.status}") if response.status!=200

                    if response.body.include? "\"userinfo\":"
                        json_response = WSAPI::Util::String.simple_parse(response.body,"(",");")
                        raise WSAPI::Exceptions::Unexpected.new("UNEXP00015") if json_response.nil?
                        json_response = JSON.parse(json_response)
                        if !json_response["userinfo"].nil? && !json_response["userinfo"]["uniqueid"].nil?
                            uid = json_response["userinfo"]["uniqueid"].to_i
                        end
                    end
                end

                raise WSAPI::Exceptions::Unexpected.new("UNEXP00016") if uid==0
                
                url = "https://weibo.com"
                response = @conn.get(url);
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00017","status: #{response.status}") if response.status!=200

                url = "https://weibo.com/ajax/profile/info?uid=#{uid}"
                headers = {"referer" => "https://weibo.com/u/#{uid}","accept" => "application/json, text/plain, */*"}
                response = @conn.get(url,headers: headers);
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00018","status: #{response.status}") if response.status!=200

                raise WSAPI::Exceptions::Unexpected.new("UNEXP00019") if !response.body.start_with? "{\"ok\":1"
                json_response = JSON.parse(response.body)
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00020") if json_response["data"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00021") if json_response["data"]["user"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00022") if json_response["data"]["user"]["id"].nil?
                raise WSAPI::Exceptions::Unexpected.new("UNEXP00023") if json_response["data"]["user"]["id"]!=uid

                add_internal_cookie_value "uid",uid

                puts ""
                puts Rainbow("Session created").white.bright
            end
        end
    end
end