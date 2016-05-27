require 'sinatra/base'
require 'sinatra'
require 'google/apis/drive_v2'
require 'google/api_client/client_secrets'
require 'json'
require "googleauth"
require 'googleauth/stores/file_token_store'
require 'oauth2'
require 'city_event_syncer'

module TourSlackBot
  class Web < Sinatra::Base

    CLIENT_SECRETS_PATH = 'client_secrets.json'
    CREDENTIALS_PATH = File.join('.credentials',
                                 "google-apps-ruby-script-creds.json")
    SCOPES = ['https://www.googleapis.com/auth/drive',
              'https://spreadsheets.google.com/feeds',
              'https://www.googleapis.com/auth/forms',
              'https://www.googleapis.com/auth/urlshortener']

    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    get '/' do
      'Service is running!'
    end

    get '/submitFormId' do
      formId = params['formId']
      begin
        credentials = JSON.parse(File.open(CREDENTIALS_PATH).read) if File.exists? CREDENTIALS_PATH
        access_token = credentials['access_token']
        puts "*** access token: #{access_token}"
        raise "Invalid/Missing access_token: #{access_token}" unless access_token and not access_token.empty?
        short_url = CityEventSyncer.update_sheet_with_updated_prefilled_url(formId, access_token)
      rescue Exception => e
        puts "Error updating sheet: #{e}"
        puts "Credentials: #{credentials}"
        return "Error updating sheet with id #{formId}"
      end

      "Updated sheet with new url: #{short_url}"
    end

    # OAuth

    get '/authorize' do
      credentials = JSON.parse(File.open(CREDENTIALS_PATH).read) if File.exists? CREDENTIALS_PATH
      if not credentials or not credentials.has_key?('access_token')
        redirect to('/google_oauth2/callback')
        return
      end

      puts "*** ACCESS TOKEN: #{credentials['access_token']}"

      'Authorized!'
    end

    get '/google_oauth2/callback' do
      client_secrets = Google::APIClient::ClientSecrets.load
      auth_client = client_secrets.to_authorization
      auth_client.update!(
        :scope => SCOPES,
        :redirect_uri => url('/google_oauth2/callback'))
      if request['code'] == nil
        auth_uri = auth_client.authorization_uri.to_s
        redirect to(auth_uri)
      else
        auth_client.code = request['code']
        auth_client.fetch_access_token!
        auth_client.client_secret = nil
        File.open(CREDENTIALS_PATH, 'w') do |f|
          f.write(auth_client.to_json)
        end
        redirect to('/authorize')
      end
    end

    get '/google7ca26596c1307a24.html' do
      'google-site-verification: google7ca26596c1307a24.html'
    end
  end
end