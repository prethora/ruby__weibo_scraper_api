# Weibo Scraper API

## Install

To be able run tests or rake tasks, install dependencies from the unzipped API directory:

```bash
bundle install
```

To install the CLI tool globally, from the unzipped API directory either run:

```bash
gem install dist/gems/weibo_scraper_api_cli-0.0.1.gem
```

or:

```bash
bundle exec rake install-cli
```
## Importing

DO NOT reference the unzipped API directory directly. Instead, to import the API into your project first create an appropriate sub directory to unpack the compiled gem into. For example, from within your project directory:

```bash
mkdir -p vendor/gems
```

And then unpack the gem:

```bash
gem unpack /path/to/weibo_scraper_api/dist/gems/weibo_scraper_api-0.0.1.gem --target vendor/gems
```

Add the following line to your Gemfile:

```
gem 'weibo_scraper_api', path: 'vendor/gems/weibo_scraper_api-0.0.1'
```

And finally run:

```bash
bundle install
```

## Configuration

Both the main gem and CLI tool use a configuration file which by default is located at `~/.wsapi/config.yaml`. If you wish to change this location, set it in the `WSAPI_CONFIG_PATH` environment variable. Note this is the path to a yaml file - not a directory. You can also specify the configuration path to use explicitly using the `config_path` named argument in the `WSAPI` class constructor, or using the `--config-path` (alias `-c`) option on any CLI command.

By default the configuration file looks like this:

```yaml
---
data_dir: "./data"    #a path relative to the configuration file containing directory - or an absolute path
user_agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)
  Chrome/94.0.4606.81 Safari/537.36    #used as value for the user-agent header in all http requests
request_timeout_seconds: 15.0    #the number of seconds after which requests to weibo.com timeout
request_retries: 3   #the number of times to retry unsuccessful requests
```

The `data_dir` value refers to a directory which will contain the following sub-directories:

* `accounts` - stores configured account sessions (see CLI below).
* `logs` - stores error log files (see Error Logging below).

Preferably DO NOT edit the configuration file directly, but instead run the `wsapi configure` CLI command to interactively edit any of the configuration values.

## CLI

The CLI tool once installed globally (see Install above) can be run through the `wsapi` command. Run `wsapi --help` for a help page. Each sub-command has its own help page as well.

#### Accounts

The primary purpose of the CLI tool is to manage multiple accounts which you can then reference when using the API in code. There is no need to provide login details, instead the QRCODE mobile app scanning mechanism is used. 

To add a new account (which you are logged into on the mobile app), run the following command:

```bash
wsapi accounts add <name>
```

`<name>` in this case is an identifier for the account, it ISN'T the username - it can be anything - it is simply the same string you have to provide to the API as the `account_name` named argument to use the account.

You will be prompted with a link to a QRCODE image, simply open it in your browser, tap "Scan QrCode" in the Weibo mobile app menu, scan the QRCODE and then tap the "Sign-in" button to confirm. Return to the command line prompt and wait for the session to be created/the account to be added. That's it, the account is ready to be used to fetch data from weibo.com.

To see a list of all accounts you have added so far run:

```bash
wsapi accounts ls
```

#### Keep Alive

Account sessions become stale 24 hours after they are created/renewed. The API automatically renews them if they are found to have staled, upon all request method calls, so you generally do not have to worry about stale sessions. However, if you do not use (and thus renew) a session for a long period of time, it may become completely invalidated, in which case you would have to add the account again using the CLI tool. (I have yet to actually experience this, I have been able to renew sessions even several weeks after no use - but I am assuming that after some period of time they would expire).

To be safe, I would recommend running the `wsapi accounts keep_alive` command as a cron job say every 5 days, to make sure any accounts you have configured but may not use regularly stay alive indefinitely. If you are using all accounts regularly though, this is unnecessary.

Note: some API requests might take a bit longer than others - this would be when a session has staled and is being renewed. This only happens once every 24 hours per account though.

#### Configure

As mentioned above, run the `wsapi configure` to interactively edit the configuration values.

## Data

A note on the data returned by the API. The data is unprocessed and returned as weibo.com provides it. I decided this was best, as any kind of processing might break the API if the data format were to change on the side of weibo.com. As it is now, if the format does change, it might break your application, but you could remedy that in your own code without having to wait for the API to be updated.

So basically you'll have to make requests and become acquainted with the data, and take what you need from it.

Note however that the testing suite does rigidly test the returned format, so if anything were to change in how weibo.com provides the data, the tests would reveal that by failing.

## Testing

#### Manual test

In the unzipped API directory (make sure to have run `bundle install` first), run the following command:

```bash
bundle exec rake test
```

This will run a test which requires you to scan a QRCODE (exactly as you would when adding a new account using the CLI tool), and will then use that temporary session to test all four API methods (`profile`, `friends`, `fans` and `statuses`). 

This test is useful to test the account adding mechanism as well as the API request methods, but obviously cannot be used as an automated test.

### Automated test

To run an automated test using an account you have already added, run the following command:

```bash
bundle exec rake test account=<name>
```

This will test all four API methods using the specified account. 

Alternatively, to just use the first account, run:

```bash
bundle exec rake test account=:first
```

## Error Logging

If any method which makes requests to weibo.com (including from an API class instance, the CLI account adding mechanism and the testing suite) raises an exception (excluding `ArgumentError` exceptions), a complete error log will be saved to the `logs` directory in the configured `data_dir` directory (defaults to `~/.wsapi/data`).

The log file name will contain a timestamp, the exception class name and the method name. If you start encountering `WSAPI::Exceptions::UnknownResponseStatus`, `WSAPI::Exceptions::UnknownResponseBody` or `WSAPI::Exceptions::Unexpected` exceptions, then you have either come across some new responses we have yet to discover, or changes have been made on the side of weibo.com which have broken the API. In such cases, just find the error log file and send it to me, and I will have everything I need to create a fix and issue you an update.

## Version Control

The zip as is contains a `.git` directory and an appropriate `.gitignore` file and is git controlled. It does not however contain any history - it only has one commit which encapsulates the current state. You just need to add a remote url to it, and it is ready to be pushed.

## Updates

The best way to proceed with updates is probably for you to provide me permissions to access the private git repository where you would be hosting the source code. If that is on github.com, my username is `prethora`. I can then apply fixes, bump the version, push changes and you can pull them on your side. You would then just have to unpack the new gem and update the version number in your Gemfile.

## Documentation

You will find complete documentation for the `WSAPI` class with examples in the [doc/WSAPI.html](doc/WSAPI.html) file.