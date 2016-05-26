require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift File.expand_path('lib')

require 'web'

run TourSlackBot::Web