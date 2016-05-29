require 'sinatra/base'
require 'sinatra'
require 'city_event_syncer'

module TourSlackBot
  class Web < Sinatra::Base

    get '/' do
      'Service is running!'
    end

    get '/submitFormId' do
      formId = params['formId']
      begin
        short_url = CityEventSyncer.update_sheet_with_updated_prefilled_url(formId)
      rescue Exception => e
        puts "Error updating sheet: #{e}"
        return "Error updating sheet with id #{formId}"
      end

      "Updated sheet with new url: #{short_url}"
    end

    get '/slackredirect' do
      if params['error']
        status 500
        raise "Error authing Slack user: #{params['error']}"
      else
        puts "params: #{params}"
        "Authorized!"
      end
    end

    get '/google7ca26596c1307a24.html' do
      'google-site-verification: google7ca26596c1307a24.html'
    end

    get '/google840911537426b968.html' do
      'google-site-verification: google840911537426b968.html'
    end
  end
end