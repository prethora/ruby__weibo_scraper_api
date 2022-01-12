require 'tmpdir'
require 'weibo_scraper_api'
require 'weibo_scraper_api/cli/api/session'

describe WSAPI do
    before(:all) do
        if !ENV["account"].nil?
            account_name = ENV["account"]
            config = WSAPI::Storage::Config.new
            data = config.get_data
            accounts = data.get_accounts
            raise ArgumentError.new("invalid account ':first', no accounts have been configured") if account_name==":first" && accounts.empty?
            raise ArgumentError.new("invalid account '#{account_name}', account not found") if account_name!=":first" && !accounts.include?(account_name)
            @config_path = config.config_path
            @account_name = account_name==":first" ? accounts.first : account_name.strip
        else
            tmp_dir_path = Dir.mktmpdir
            at_exit { FileUtils.remove_entry(tmp_dir_path) }
            @config_path = File.join(tmp_dir_path,"config.yaml")
            config = WSAPI::Storage::Config.new(@config_path)
            config.user_agent = WSAPI::Storage::Config.new.user_agent
            config.save
            @sm = WSAPI::Storage::SessionManager.new(config)
            @account_name = "test_account"
        end
    end

    if ENV["account"].nil?
        context "login (account adding)" do
            it "works as expected" do
                @sm.add_account(@account_name)
                @sm.get_session(@account_name)
            end
        end
    end

    context "#profile" do
        it "works as expected" do
            wsapi = WSAPI.new(config_path: @config_path,account_name: @account_name)
            profile = wsapi.profile(wsapi.my_uid)
            expect(profile.keys.sort).to eq ["detail","info"]
            expect(profile["detail"].keys.sort).to eq ["birthday", "created_at", "desc_text", "description", "gender", "label_desc", "location", "sunshine_credit", "verified_url"]
            expect(profile["info"].keys.sort).to eq ["blockText", "tabList", "user"]
            expect(profile["info"]["user"].keys.sort).to eq ["avatar_hd", "avatar_large", "cover_image_phone", "description", "domain", "follow_me", "followers_count", "followers_count_str", "following", "friends_count", "gender", "id", "idstr", "is_muteuser", "is_star", "location", "mbrank", "mbtype", "pc_new", "planet_video", "profile_image_url", "profile_url", "screen_name", "special_follow", "statuses_count", "url", "user_type", "verified", "verified_type", "weihao", "wenda"]
            expect(profile["info"]["user"]["id"].to_s).to eq wsapi.my_uid.to_s
        end
    end

    context "#friends" do
        it "works as expected" do
            wsapi = WSAPI.new(config_path: @config_path,account_name: @account_name)
            friends = wsapi.friends(wsapi.my_uid)
            expect(friends.keys.sort).to eq ["has_filtered_attentions", "has_filtered_fans", "next_cursor", "previous_cursor", "total_number", "use_sink_stragety", "users"]
        end
    end

    context "#fans" do
        it "works as expected" do
            wsapi = WSAPI.new(config_path: @config_path,account_name: @account_name)
            fans = wsapi.fans(wsapi.my_uid)
            expect(fans.keys.sort).to eq ["display_total_number", "display_total_number_str", "has_filtered_attentions", "has_filtered_fans", "next_cursor", "previous_cursor", "total_number", "use_sink_stragety", "users"]
        end
    end

    context "#statuses" do
        it "works as expected" do
            wsapi = WSAPI.new(config_path: @config_path,account_name: @account_name)
            statuses = wsapi.statuses(wsapi.my_uid)
            expect(statuses.keys.sort).to eq ["bottom_tips_text", "bottom_tips_visible", "list", "since_id", "status_visible", "topicList"]
        end
    end
end