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

Both the main gem and CLI tool use a configuration file which by default is located at `~/.wsapi/config.yaml`. If you wish to change this location, set it to the `WSAPI_CONFIG_PATH` environment variable. Note this is the path to a yaml file - not a directory. You can also specify the configuration path to use explicitly using the `config_path` named argument in the `WSAPI` class constructor, or using the `--config-path` (alias `-c`) option on any CLI command.

By default the configuration file looks like this:

```yaml
---
data_dir: "./data"    #a path relative to the configuration file containing directory - or an absolute path
user_agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)
  Chrome/94.0.4606.81 Safari/537.36    #used as value for the user-agent header for all http requests
request_timeout_seconds: 15.0    #the number of seconds after which requests to weibo.com timeout
request_retries: 3   #the number of times to retries unsuccessful requests
```

The `data_dir` value refers to a directory which will contain the following sub-directories:

* `accounts` - stores configured account sessions (see CLI below).
* `logs` - stores error log files (see Error Logging below).

Preferably DO NOT edit the configuration file directly, but instead run the `wsapi configure` CLI command to edit any of the configuration values.

## CLI

The CLI tool once installed globally (see Install above) can be run through the `wsapi` command. Run `wsapi --help` for a help page. Each sub-command has its own help page as well.

#### Accounts

The primary purpose of the CLI tool is to manage multiple accounts which you can then reference when using the API in code. There is no need to provide login details, instead the QRCODE mobile app scanning mechanism is used. 

To add a new account (which you are logged into on the mobile app), run the following command:

```bash
wsapi accounts add <name>
```

`<name>` in this case is an identifier for the account, it ISN'T the username - it can be anything - it is simply the same string you have to provide to the API as the `account_name` named argument to use the account.

You will be prompted with a link to a QRCODE image, simply open it in your browser, tap "Scan QrCode" in the Weibo mobile app menu, scan the image and then tap the "Sign-in" button to confirm. Return to command line prompt and wait for the session to be create/account to be added. That's it, the account is ready to be used to fetch data from weibo.com.

To see a list of all accounts you have added so far run:






## Data

## Keep Alive

## Testing

## Error Logging

## Version Control

## Updates

## Documentation