require 'faraday'
require 'faraday/net_http'
require 'faraday-cookie_jar'
require 'faraday_middleware'
require 'http/cookie_jar'

Faraday.default_adapter = :net_http

class WSAPI
    module Util
        class HttpClient
            def initialize(jar: HTTP::CookieJar.new,user_agent: nil,follow_redirects: false,log: false)
                @baseHeaders = {
                    "pragma" => "no-cache",
                    "cache-control" => "no-cache",
                    "sec-ch-ua" => "\"Chromium\";v=\"94\", \"Google Chrome\";v=\"94\", \";Not A Brand\";v=\"99\"",
                    "sec-ch-ua-mobile" => "?0",
                    "sec-ch-ua-platform" => "\"Linux\"",
                    "upgrade-insecure-requests" => "1",
                    "user-agent" => !user_agent.nil? ? user_agent : "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36",
                    "accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
                    "sec-fetch-site" => "none",
                    "sec-fetch-mode" => "navigate",
                    "sec-fetch-user" => "?1",
                    "sec-fetch-dest" => "document",
                    "accept-language" => "en-US,en;q=0.9,fr-FR;q=0.8,fr;q=0.7,es;q=0.6",
                }

                @conn = Faraday.new do |builder|
                    builder.use FaradayMiddleware::FollowRedirects if follow_redirects
                    builder.use :cookie_jar,jar: jar
                    builder.response :logger if log
                    builder.adapter Faraday.default_adapter
                end                  
            end

            def get(url,headers: {})
                @conn.get(url,{},@baseHeaders.merge(headers))
            end
        end
    end
end