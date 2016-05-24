$LOAD_PATH.unshift File.expand_path('lib/tour_slackbot', File.dirname(__FILE__))

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

run TourSlackBot::Web