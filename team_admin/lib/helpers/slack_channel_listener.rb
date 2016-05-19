require 'slack-ruby-client'
require 'sinatra/activerecord'
require './lib/models/event'
require './lib/helpers/form_copy_apps_script_executor'

class SlackChannelListener
	def initialize
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
		end

		@web_client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
		@rt_client = Slack::RealTime::Client.new
		@apps_script_executor = FormCopyAppsScriptExecutor.new
	end

	def start_listening!
		# safety so we don't start listener twice
		return if @listening
		@listening = true

		update_if_necessary

		# on create_channel, get slack channels other than "general" and "random"
		@rt_client.on :channel_created do
			update_if_necessary
		end

		# kick off loop to update when new channels created
		@rt_client.start!
	end

	private

  def update_if_necessary
		channels = get_slack_channels
		return if channels.empty?
		channels.each do |c|
			# Update db with new events for new channels
			name = c['name']
			e = Event.find_or_create_by_title(name)
			if e.form_key.nil?
				form_key = @apps_script_executor.copy_form(name, e.spreadsheet_key)
				e.form_key = form_key unless form_key.empty?
				e.save!
			end
		end
  end

  def get_slack_channels
    puts 'Getting Slack Channels...'
    # note: If we wanted private channels, we'd use groups_list
    channels = @web_client.channels_list(exclude_archived: true)['channels'] || []
    channels.reject! { |c| c["name"] == "general" || c["name"] == "random" }
    channels
  end
end
