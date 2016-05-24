require 'sinatra/base'

module SlackGoogleBot
  class Web < Sinatra::Base
    get '/' do
      'Tour Slackbot running!'
    end
  end
end