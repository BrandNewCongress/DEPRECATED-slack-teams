require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'
require 'utils/configure_clients'
require 'form_copy_apps_script_executor'
require 'form_prefilled_url_script_executor'

Dotenv.load

EVENTS_CITIES_SHEET_INDEX = 0
EVENTS_TODO_FORM_CITY_INDEX = 2
EVENTS_TODO_FORM_COL_INDEX = 11
EVENTS_TODO_RESPONSES_COL_INDEX = 12

module CityEventSyncer

  CITY_EVENT_SYNCER_TOPIC_PREFIX = "Click here to update your progress:"

  extend ConfigureClients

  # Google Drive

  # Gets a hash of all cities in our Google Spreadsheet
  # Returns a hash in the format { "City Name" => "[FormID, ResponsesID]" }
  def self.get_cities
    cities_hash = {}
    session = configure_google_drive
    begin
      sheet = session.spreadsheet_by_key(ENV['EVENTS_SPREADSHEET_ID'])
        .worksheets[EVENTS_CITIES_SHEET_INDEX]
      # Get all cities
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_TODO_FORM_CITY_INDEX]
        todo_form_url = sheet[row, EVENTS_TODO_FORM_COL_INDEX]
        responses_sheet = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        cities_hash[city] = [todo_form_url, responses_sheet]
      end
    rescue Exception => e
      puts "Error while getting cities: #{e}"
    end

    cities_hash
  end

  # Create Google Form and Responses Sheet per-city if it doesn't already exist, add to sheet
  def self.update_sheet
    session = configure_google_drive
    form_copy_executor = configure_copy_apps_script_executor
    begin
      sheet = session.spreadsheet_by_key(ENV['EVENTS_SPREADSHEET_ID'])
        .worksheets[EVENTS_CITIES_SHEET_INDEX]
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_TODO_FORM_CITY_INDEX]
        todo_form_url = sheet[row, EVENTS_TODO_FORM_COL_INDEX]
        responses_sheet_key = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        # TODO: This is ugly, clean up + test.
        if todo_form_url.empty? and responses_sheet_key.empty?
          responses_sheet_key = session.create_spreadsheet("#{city} BNC Tour To-Do Responses").key
          todo_form_url = form_copy_executor.copy_form(city, responses_sheet_key)
          puts "Updating #{city}\nForm: #{todo_form_url}\nResponses: #{responses_sheet_key}"
        elsif todo_form_url.empty? and not responses_sheet_key.empty?
          todo_form_url = form_copy_executor.copy_form(city, responses_sheet_key)
          puts "Updating #{city}\nForm: #{todo_form_url}\nResponses: #{responses_sheet_key}"
        elsif not todo_form_url.empty? and responses_sheet_key.empty?
          responses_sheet_key = session.create_spreadsheet("#{city} BNC Tour To-Do Responses").key
          todo_form_url = form_copy_executor.copy_form(city, responses_sheet_key)
          puts "Updating #{city}\nForm: #{todo_form_url}\nResponses: #{responses_sheet_key}"
        else
          puts "#{city} up-to-date with form #{todo_form_url} and responses sheet #{responses_sheet_key} -- nothing to do!"
        end
        sheet[row, EVENTS_TODO_FORM_COL_INDEX] = todo_form_url
        sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX] = responses_sheet_key
        sheet.save
      end
    rescue Exception => e
      puts "Error while updating sheet: #{e}"
    end
  end

  # Google Apps Executor

  def self.get_updated_prefilled_url(formId)
    executor = configure_prefilled_apps_script_executor
    response = executor.get_prefilled_url_for_latest_responses(formId)
    begin
      short_url = response[0]
      destination = response[1]
    rescue Exception => e
      unless short_url and destination
        puts "Error getting updated prefilled url and destination: #{e}"
      end
    end
    return response
  end

  def self.update_sheet_with_updated_prefilled_url(formId)
    begin
      response = get_updated_prefilled_url(formId)
      puts "Got Response: #{response}"
      short_url = response[0]
      dest = response[1]
      unless short_url and dest
        puts "Error getting updated prefilled url and destination"
        return
      end
      session = configure_google_drive
      sheet = session.spreadsheet_by_key(ENV['EVENTS_SPREADSHEET_ID'])
        .worksheets[EVENTS_CITIES_SHEET_INDEX]
      matching_idx = -1
      city = ''
      (2..sheet.num_rows).each do |row|
        sheet_dest = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        if sheet_dest == dest
          matching_idx = row
          city = sheet[row, EVENTS_TODO_FORM_CITY_INDEX]
          break
        end
      end
      if matching_idx == -1
        puts "Could not find a matching index"
        return
      end
      sheet[matching_idx, EVENTS_TODO_FORM_COL_INDEX] = short_url
      sheet.save

      # Reset Slack room topic with new URL
      channel_id = slack_channel_id_for_city_name(city)
      topic = "#{CITY_EVENT_SYNCER_TOPIC_PREFIX} #{short_url}"
      puts "Setting in Slack Channel #{channel_id} for city #{city}: \"#{topic}\""
      channels_set_topics({ channel_id => topic })

      puts "Updated sheet with new form url: #{short_url}"
      return short_url
    rescue Exception => e
      puts "Error Updating Sheet: #{e}"
    end
  end

  # Slack

  # Create one public slack channel for each city
  # Returns all public Slack channel names
  def self.create_channels(channel_names)
    client = configure_slack
    channel_names.each do |n|
      begin
        client.channels_create(name: n)
      rescue Exception => e
        puts "Error while creating channel for #{n}: #{e}"
      end
    end
  end

  # Returns all channels in the format { "ChannelName" => "ChannelID"}
  def self.list_channels
    client = configure_slack
    begin
      channels = client.channels_list(exclude_archived: true)['channels'] || []
    rescue Exception => e
      puts "Error while getting channels list: #{e}"
    end

    # channels.map { |c| c.name => c.id }.to_h
    Hash[channels.map { |c| [c.name, c.id] }]
  end

  def self.channels_set_topics(channel_id_to_topic_hash)
    client = configure_slack
    channel_id_to_topic_hash.each do |id, t|
      begin
        topic = channel_get_topic(id)
        client.channels_setTopic(channel: id, topic: t) unless topic == t
      rescue Exception => e
        puts "Error while setting topic: #{e}\nChannel: #{id}\nTopic: #{t}"
      end
    end
  end

  def self.channel_get_topic(channel_id)
    client = configure_slack
    begin
      t = client.channels_info(channel: channel_id)['channel']['topic']['value']
    rescue Exception => e
      puts "Error while getting channel topic: #{e}\nChannel: #{channel_id}"
    end
    t
  end

  def self.channels_invite_bot(channel_ids)
    client = configure_slack
    channel_ids.each do |id|
      begin
        client.channels_invite(channel: id, user: ENV['SLACK_BOT_USER_ID'])
      rescue Exception => e
        puts "Error while inviting bot to channels: #{e}"
      end
      channel_ids
    end
  end

  def self.slack_channel_id_for_city_name(city_name)
    slack_name = slack_name_for_city_name(city_name)
    channel_id_hash = CityEventSyncer.list_channels
    channel_id = channel_id_hash[slack_name]

    channel_id
  end

  # Util

  def self.slack_name_for_city_name(city_name)
    city_name.downcase.gsub(' ', '-').gsub('.', '_')
  end
end
