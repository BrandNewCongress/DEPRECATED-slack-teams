require 'sinatra/base'
require 'sinatra'
require 'google/apis/drive_v2'
require 'google/api_client/client_secrets'
require 'json'
require "googleauth"
require 'googleauth/stores/file_token_store'
require 'oauth2'
require 'city_event_syncer'

enable :sessions

module TourSlackBot

  SCOPES = ['https://www.googleapis.com/auth/drive',
            'https://spreadsheets.google.com/feeds',
            'https://www.googleapis.com/auth/forms',
            'https://www.googleapis.com/auth/urlshortener']

  CLIENT_SECRETS_PATH = 'google_apps_client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                               "google-apps-ruby-script-creds.yaml")            

  unless GOOGLE_API_CLIENT_ID = ENV['GOOGLE_API_CLIENT_ID']
    raise "Missing ENV['GOOGLE_API_CLIENT_ID']"
  end
   
  unless GOOGLE_API_CLIENT_SECRET = ENV['GOOGLE_API_CLIENT_SECRET']
    raise "Missing ENV['GOOGLE_API_CLIENT_SECRET']"
  end

  class Web < Sinatra::Base
    get '/' do
      'Service is running!'
    end

    get '/submitFormId' do
      unless session.has_key?(:credentials)
        redirect to('/google_oauth2/callback')
      end

      formId = params['formId']
      begin
        short_url = CityEventSyncer.update_sheet_with_updated_prefilled_url(formId)
      rescue Exception => e
        puts "Error updating sheet: #{e}"
        return "Error updating sheet with id #{formId}"
      end

      "Updated sheet with new url: #{short_url}"
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
        session[:credentials] = auth_client.to_json
        redirect to('/submitFormId')
      end        
    end

    get '/google7ca26596c1307a24.html' do
      'google-site-verification: google7ca26596c1307a24.html'
    end
  end
end



# FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
# client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
# token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
# authorizer = Google::Auth::UserAuthorizer.new(
#   client_id, SCOPES, token_store)
# user_id = 'default'
# credentials = Google::Auth::UserRefreshCredentials.new(
#   client_id: ENV['GOOGLE_API_CLIENT_ID'],
#   client_secret: ENV['GOOGLE_API_CLIENT_SECRET'],
#   scope: SCOPES,
#   redirect_uri: "https://bnc-slack-teams.herokuapp.com/google_oauth2/callback")
# authorizer.fetch_access_token!