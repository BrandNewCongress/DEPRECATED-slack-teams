require 'dotenv'

require 'slack-ruby-bot'
require 'eventmachine'

Dotenv.load
$LOAD_PATH.unshift File.expand_path('lib')

require 'tour_slackbot'
require 'web'

Thread.new do
  begin
    TourSlackBot::App.instance.run
  rescue Exception => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

EM.run do
  token = ENV['SLACK_BOT_TOKEN']
  raise "Missing ENV['SLACK_BOT_TOKEN']!" unless token
  bot = TourSlackBot::Server.new(token: token, aliases: ['bncbot'])
  bot.start_async
end

run TourSlackBot::Web