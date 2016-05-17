require 'sinatra'
require 'sinatra/base'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'tilt/erb'
require './lib/config/environments'
require './lib/models/event'

class TeamAdminApp < Sinatra::Base

	SLACK_PREFIX = "https://adampricesandbox.slack.com/messages"

	get '/' do
		@events = Event.all
		erb :index
	end
end