require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'

class SlackChannelCreationListener
  def initialize
    # load environment
    Dotenv.load

    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
      config.logger = Logger.new(STDOUT)
      config.logger.level = Logger::INFO
      fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
    end

    # setup clients
    @client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
    @rt_client = Slack::RealTime::Client.new
    @gd_session = GoogleDrive.saved_session("../google_drive_config.json")
  end

  def start!
    # update google sheets initially,
    update_google_sheets_if_necessary

    @rt_client.on :channel_created do
      update_google_sheets_if_necessary
    end

    # and kick off loop to update when new channels created
    @rt_client.start!
  end

  private

  def update_google_sheets_if_necessary
    # on create_channel, get all slack channels other than "general" and "random"
    channels = get_slack_channels
    # post to google sheets
    update_google_sheets(channels) unless channels.empty?
  end

  def get_slack_channels
    puts 'Getting Slack Channels...'
    # note: If we wanted private channels, we'd use groups_list
    channels = @client.channels_list(exclude_archived: true)['channels'] || []
    channels.reject! { |c| c["name"] == "general" || c["name"] == "random" }
    channels.each do |c|
      puts "- id: #{c["id"]}, name: #{c["name"]}"
    end
    channels
  end

  def update_google_sheets(channels)
    puts 'Updating Google Sheets...'
    begin
      ws = @gd_session.spreadsheet_by_key(ENV['GOOGLE_DRIVE_SHEET_ID']).worksheets[0]
      channels.each_with_index do |c, idx|
        # Google Sheets are indexed [row, col] and start at top-left [1, 1]
        ws[idx + 1, 1] = c['name']
        ws[idx + 1, 2] = c['id']
        puts "- Updated cells: |#{c['name']}|#{c['id']}|"
      end
      ws.save
    rescue Exception => e
      $stderr.print "Failed to update Google Sheets\n#{e.inspect}"
    end
  end
end

s = SlackChannelCreationListener.new
s.start!
