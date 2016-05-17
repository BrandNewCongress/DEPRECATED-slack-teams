require './lib/helpers/slack_channel_listener'
require './lib/app'
require 'dotenv'

Dotenv.load

run TeamAdminApp

Thread.abort_on_exception = true
Thread.new do
	begin
		l = SlackChannelListener.new
		l.start_listening!
	rescue Exception => e
		STDERR.puts "ERROR: #{e}"
		STDERR.puts e.backtrace
	end
end
