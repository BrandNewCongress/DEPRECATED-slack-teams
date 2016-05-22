require 'slack-ruby-client'
require 'dotenv'

Dotenv.load

module ChannelsArchiver
	def self.archive_channels
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
		end

		# Archives all public channels in a Slack team
		client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
		channels = client.channels_list(exclude_archived: true)['channels'] || []
		channels.reject! { |c| c["name"] == "general" || c["name"] == "random" }
		if channels.empty?
			puts "No channels to archive" if channels.count == 0
			return
		end
		channels.each do |c|
			begin
				client.channels_archive(channel: c.id)
			rescue Exception => e
				puts "Error: #{e.backtrace}"
			end
		end
	end
end

if __FILE__ == $0
	ChannelsArchiver.archive_channels
end