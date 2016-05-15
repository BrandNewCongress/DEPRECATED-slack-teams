require 'sinatra'
require 'sinatra/base'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'tilt/erb'
require './lib/config/environments'
require './lib/models/event'
require './lib/helpers/slack_channel_listener'


class TeamAdminApp < Sinatra::Base

	SLACK_PREFIX = "https://adampricesandbox.slack.com/messages"

	def self.start_listening!
		l = SlackChannelListener.new
		l.start_listening!
	end

	get '/' do
		@events = Event.all
		erb :index
	end

	start_listening!
end