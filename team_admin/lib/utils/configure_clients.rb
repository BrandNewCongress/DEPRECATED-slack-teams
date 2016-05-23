require 'slack-ruby-client'
require 'dotenv'

module ConfigureClients
	def configure_slack
		Dotenv.load
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
		end

		client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
		client
	end

	def configure_google_drive
		session = GoogleDrive.saved_session("../../../../google_drive_config.json")
		session
	end
end