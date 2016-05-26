require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift File.expand_path('lib')

require 'web'

use Rack::Session::Cookie, :key => 'rack.session',
                           :secret => ENV['RACK_SECRET']

run TourSlackBot::Web