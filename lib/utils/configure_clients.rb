require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'
require 'form_copy_apps_script_executor'

Dotenv.load

module ConfigureClients
  def configure_slack
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
      fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
    end

    client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
    client
  end

  def configure_google_drive(auth)
    session = GoogleDrive.login_with_oauth(auth.access_token)

    session
  end

  def configure_apps_script_executor
    executor = FormCopyAppsScriptExecutor.new
    executor
  end
end