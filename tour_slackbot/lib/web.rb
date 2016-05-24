require 'sinatra/base'
require 'city_event_syncer'

module TourSlackBot
  class Web < Sinatra::Base
    get '/' do
      'Tour Slackbot running!'
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
  end
end