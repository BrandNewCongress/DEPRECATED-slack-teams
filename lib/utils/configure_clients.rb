require 'slack-ruby-client'
require 'google/api_client/client_secrets'
require 'google_drive'
require 'google/api_client/auth/key_utils'
require 'googleauth'
require 'fileutils'
require 'base64'
require 'dotenv'
require 'form_copy_apps_script_executor'
require 'form_add_questions_script_executor'

Dotenv.load

module ConfigureClients

  SCOPES = ['https://www.googleapis.com/auth/drive',
            'https://www.googleapis.com/auth/forms',
            'https://www.googleapis.com/auth/urlshortener']

  def configure_slack
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
      fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
    end

    client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
    client
  end

  def configure_google_drive
    begin
      key = Google::APIClient::KeyUtils.load_from_pkcs12(Base64.decode64(ENV['P12B64']), ENV['GOOGLE_SERVICE_ACCT_PASS'])
      client = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => SCOPES,
        :issuer => ENV['GOOGLE_SERVICE_ACCOUNT_ISSUER_EMAIL'],
        :signing_key => key)
      auth_client = client.dup
      auth_client.sub = ENV['GOOGLE_SERVICE_ACCOUNT_USER_EMAIL']
      client = auth_client
      client.fetch_access_token!
    rescue Exception => e
      puts "Exception: #{e}"
    end

    session = GoogleDrive.login_with_oauth(client.access_token)

    session
  end

  def configure_copy_apps_script_executor
    executor = FormCopyAppsScriptExecutor.new

    configure_apps_script_executor(executor)
  end

  def configure_prefilled_apps_script_executor
    executor = FormPrefilledUrlScriptExecutor.new

    configure_apps_script_executor(executor)
  end

  def configure_add_questions_script_executor
    executor = FormAddQuestionsScriptExecutor.new

    configure_apps_script_executor(executor)
  end

  private

  def configure_apps_script_executor(executor)
    key = Google::APIClient::KeyUtils.load_from_pkcs12(
      Base64.decode64(ENV['P12B64']), ENV['GOOGLE_SERVICE_ACCT_PASS'])
    service = Google::Apis::ScriptV1::ScriptService.new
    service.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => SCOPES,
      :issuer => ENV['GOOGLE_SERVICE_ACCOUNT_ISSUER_EMAIL'],
      :signing_key => key)
    auth_client = service.authorization.dup
    auth_client.sub = ENV['GOOGLE_SERVICE_ACCOUNT_USER_EMAIL']
    service.authorization = auth_client
    executor.client = service
    service.authorization.fetch_access_token!
    executor
  end


end