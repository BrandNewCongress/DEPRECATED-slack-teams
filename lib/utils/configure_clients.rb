require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'
require "googleauth"
require 'googleauth/stores/file_token_store'
require 'form_copy_apps_script_executor'


module ConfigureClients
  def configure_slack
    Dotenv.load
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
      fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
    end

    client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
    client
  end

  def configure_google_drive
    auth = authorize
    session = GoogleDrive.login_with_oauth(auth.access_token)

    session
  end

  def configure_apps_script_executor
    executor = FormCopyAppsScriptExecutor.new
    executor
  end


  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPES, token_store)
    user_id = 'default'
    credentials = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_API_CLIENT_ID'],
      client_secret: ENV['GOOGLE_API_CLIENT_SECRET'],
      scope: [
        "https://www.googleapis.com/auth/drive",
        "https://spreadsheets.google.com/feeds/",
      ],
      redirect_uri: "https://bnc-slack-teams.herokuapp.com/google_oauth2/callback")
    authorizer.fetch_access_token!

    authorizer
  end
end