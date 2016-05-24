require 'sinatra/base'

module TourSlackBot
  class Web < Sinatra::Base
    get '/' do
      'Tour Slackbot running!'
    end
  end
end