require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'

# load environment
Dotenv.load

Slack.configure do |config|
	config.token = ENV['SLACK_API_TOKEN']
	config.logger = Logger.new(STDOUT)
	config.logger.level = Logger::INFO
	fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
end

# setup clients
client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
rt_client = Slack::RealTime::Client.new
gd_session = GoogleDrive.saved_session("../google_drive_config.json")

rt_client.on :channel_created do
	# whenever a channel is created,
	# get all slack channels other than "general" and "random"
	puts 'Getting Slack Channels...'
	# note: If we wanted private channels, we'd use groups_list
	channels = client.channels_list(exclude_archived: true)['channels'] || []
	channels.reject! { |c| c["name"] == "general" || c["name"] == "random" }
	channels.each do |c|
		puts "- id: #{c["id"]}, name: #{c["name"]}"
	end

	# post to google sheets
	puts 'Updating Google Sheets'
	begin
		ws = gd_session.spreadsheet_by_key(ENV['GOOGLE_DRIVE_SHEET_ID']).worksheets[0]
		puts "Worksheet Title: #{ws.title}"
		channels.each_with_index do |c, idx|
			# Google Sheets are indexed [row, col] and start at top-left [1, 1]
			ws[idx + 1, 1] = c["name"]
			ws[idx + 1, 2] = c["id"]
		end
		ws.save
	rescue Exception => e
		$stderr.print "Failed to update Google Sheets\n#{e.inspect}"
	end

end

rt_client.start!