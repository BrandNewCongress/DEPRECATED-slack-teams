require 'dotenv'
require 'slack'
require 'google_drive'

# load environment
Dotenv.load

Slack.configure do |config|
	config.token = ENV['SLACK_API_TOKEN']
end

gd_session = GoogleDrive.saved_session("../google_drive_config.json")

# setup clients
client = Slack::Client.new
rt_client = Slack::RealTime::Client.new

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
	ws = gd_session.spreadsheet_by_key(ENV['GOOGLE_DRIVE_SHEET_ID']).worksheets[0]
	channels.each_with_index do |c, idx|
		ws[idx, 1] = c["name"]
		ws[idx, 2] = c["id"]
	end
	ws.save

end

rt_client.start!