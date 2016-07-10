require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'
require 'utils/configure_clients'
require 'form_copy_apps_script_executor'
require 'form_prefilled_url_script_executor'

Dotenv.load

EVENTS_DATE_COL_INDEX = 1
EVENTS_CITY_COL_INDEX = 2
EVENTS_STATE_COL_INDEX = 3
EVENTS_ZIP_COL_INDEX = 4
EVENTS_NB_COL_INDEX = 5
EVENTS_FB_COL_INDEX = 6
EVENTS_TODO_FORM_URL_COL_INDEX = 7
EVENTS_TODO_RESPONSES_COL_INDEX = 8

module CityEventSyncer

  CITY_EVENT_SYNCER_TOPIC_PREFIX = "Click here to update your progress:"
  CITY_EVENT_SYNCER_PURPOSE_FORMAT_STR = "Organizing the event in %s%s"

  extend ConfigureClients

  ###########################################################################
  # Google Drive
  ###########################################################################  

  # Gets a hash of all cities in our Google Spreadsheet
  # Returns a hash in the format { "City Name" => "[FormID, ResponsesID]" }
  def self.get_cities
    cities_hash = {}
    session = configure_google_drive
    begin
      sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
        .worksheets[0]
      # Create list of dupes so we know which ones to append date to
      cities = []
      dupes = []
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_CITY_COL_INDEX]
        dupes.push(city) if cities.include? city
        cities.push(city)
      end
      # Get all cities
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_CITY_COL_INDEX]
        date = sheet[row, EVENTS_DATE_COL_INDEX]
        # append date to city if it's a dupe
        # also remove 2016, too many chars
        city = "#{city}-#{date.gsub('/2016','').gsub('/','-')}" if dupes.include? city
        todo_form_url = sheet[row, EVENTS_TODO_FORM_URL_COL_INDEX]
        responses_sheet = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        cities_hash[city] = [todo_form_url, responses_sheet]
      end
    rescue Exception => e
      puts "Error while getting cities: #{e}"
    end

    cities_hash
  end

  def self.get_cities_to_dates_hash
    cities_hash = {}
    session = configure_google_drive
    begin
      sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
        .worksheets[0]
      # Get all cities
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_CITY_COL_INDEX]
        date = sheet[row, EVENTS_DATE_COL_INDEX]
        cities_hash[city] = date
      end
    rescue Exception => e
      puts "Error while getting cities to date hash: #{e}"
    end

    cities_hash
  end

  # Create Google Form and Responses Sheet per-city if it doesn't already exist, add to sheet
  def self.update_sheet
    session = configure_google_drive
    form_copy_executor = configure_copy_apps_script_executor
    begin
      sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
        .worksheets[0]
      (2..sheet.num_rows).each do |row|
        city = sheet[row, EVENTS_CITY_COL_INDEX]
        todo_form_url = sheet[row, EVENTS_TODO_FORM_URL_COL_INDEX]
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
        sheet[row, EVENTS_TODO_FORM_URL_COL_INDEX] = todo_form_url
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
      sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
        .worksheets[0]
      matching_idx = -1
      city = ''
      date = ''
      (2..sheet.num_rows).each do |row|
        sheet_dest = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        if sheet_dest == dest
          matching_idx = row
          city = sheet[row, EVENTS_CITY_COL_INDEX]
          date = sheet[row, EVENTS_DATE_COL_INDEX]
          break
        end
      end
      if matching_idx == -1
        puts "Could not find a matching index"
        return
      end
      sheet[matching_idx, EVENTS_TODO_FORM_URL_COL_INDEX] = short_url
      sheet.save

      # Reset Slack room topic with new URL
      channel_id = slack_channel_id_for_city_name(city)
      topic = "#{CITY_EVENT_SYNCER_TOPIC_PREFIX} #{short_url}"
      puts "Setting in Slack Channel #{channel_id} for city #{city}: \"#{topic}\""
      channels_set_topics({ channel_id => topic })

      puts "Updated sheet with new form url: #{short_url}"

      # Update response sheet with latest response
      CityEventSyncer.sync_event_response(city, date)
      puts "Updated All Responses sheet with latest response"

      return short_url
    rescue Exception => e
      puts "Error Updating Sheet: #{e}"
    end
  end

  def self.sync_all_responses_sheet
    puts "Syncing all event responses..."
    begin
      session = configure_google_drive

      # Get all the event responses sheet keys
      event_info_list = []
      all_responses_sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
          .worksheets[0]
      (2..all_responses_sheet.num_rows).each do |row|
        date = all_responses_sheet[row, EVENTS_DATE_COL_INDEX]
        city = all_responses_sheet[row, EVENTS_CITY_COL_INDEX]
        todo_resp = all_responses_sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
        info = [date, city, todo_resp]
        event_info_list.push(info)
      end

      # Fill up list of responses using last row in each response sheet
      responses = []
      event_info_list.each do |e|
        date = e[0] || ''
        city = e[1] || ''
        dest_key = e[2] || ''
        puts "Fetching Destination Sheet for event #{city}-#{date}..."
        if dest_key.empty?
          num_cols = 0
        else
          dest_sheet = session
            .spreadsheet_by_key(dest_key)
            .worksheets[0]
          num_cols = dest_sheet.num_cols
        end

        resp = []
        if dest_key.empty? or dest_sheet.num_rows <= 1
          # Fill array with empty strings, prepended by event key
          resp = resp + Array.new(num_cols) {""}
        else
          (2..num_cols).each do |col|
            resp.push(dest_sheet[dest_sheet.num_rows, col])
          end
        end
        puts "Latest Response for #{city}-#{date} is\n#{resp}"
        responses.push(resp)
      end

      #Get the "all responses sheet" and write all responses to it
      start_col = EVENTS_TODO_RESPONSES_COL_INDEX + 1
      responses.each_with_index do |row, idx|
        (start_col..(start_col + row.length)).each do |col|
          all_responses_sheet[idx + 2, col] = row[col - start_col]
        end
      end
      all_responses_sheet.save
      puts "Finished writing to All Responses Sheet"
      
    rescue Exception => e
      puts "Error syncing responses sheet: #{e}"
    end
  end

  def self.sync_event_response(event_city, event_date)
    puts "Syncing latest response for the event in #{event_city} on #{event_date}..."

    begin
      session = configure_google_drive

      # Get the destination key for the event
      all_responses_sheet = session.spreadsheet_by_key(ENV['EVENTS_ALL_RESPONSES_SPREADSHEET_ID'])
        .worksheets[0]
      dest_key = ''
      (2..all_responses_sheet.num_rows).each do |row|
        city = all_responses_sheet[row, EVENTS_CITY_COL_INDEX]
        date = all_responses_sheet[row, EVENTS_DATE_COL_INDEX]
        if city == event_city and date == event_date
          dest_key = all_responses_sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
          break
        end
      end
      if dest_key.empty?
        puts "Could not find matching event"
        return
      end

      # Get the latest responses
      dest_sheet = session.spreadsheet_by_key(dest_key).worksheets[0]
      latest_response = []
      start_col = EVENTS_TODO_RESPONSES_COL_INDEX + 1
      if dest_sheet.num_rows > 1
        (2..dest_sheet.num_cols).each do |col|
          latest_response.push(dest_sheet[dest_sheet.num_rows, col])
        end
      else
        latest_response = latest_response + Array.new(dest_sheet.num_cols) {""}
      end
      
      puts "Latest Response: #{latest_response}"
      
      # Write the response to the All Responses Sheet
      (2..all_responses_sheet.num_rows).each do |row|
        resp_city = all_responses_sheet[row, EVENTS_CITY_COL_INDEX]
        resp_date = all_responses_sheet[row, EVENTS_DATE_COL_INDEX]
        if resp_city == event_city and resp_date == event_date
          (start_col..(start_col + latest_response.length)).each do |col|
            all_responses_sheet[row, col] = latest_response[col - start_col]
          end
        end
      end
      all_responses_sheet.save
      puts "Finished writing responses for event in #{event_city} on #{event_date}"
    rescue Exception => e
      puts "Error syncing event response: #{e}"
    end
  end

  ###########################################################################
  # Slack
  ###########################################################################  

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
    puts "Setting topics for hash:\n#{channel_id_to_topic_hash}"
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
        puts "Error while inviting bot to channel #{id}: #{e}"
      end
    end
    channel_ids
  end

  def self.channels_set_purpose(channel_ids_to_purpose_hash)
    client = configure_slack
    channel_ids_to_purpose_hash.each do |id, purpose|
      begin
        client.channels_setPurpose(channel: id, purpose: purpose)
      rescue Exception => e
        puts "Error while setting purpose in channel #{id}: #{e}"
      end
    end
    channel_ids_to_purpose_hash
  end

  def self.slack_channel_id_for_city_name(city_name)
    slack_name = slack_name_for_city_name(city_name)
    channel_id_hash = CityEventSyncer.list_channels
    channel_id = channel_id_hash[slack_name]

    channel_id
  end

  # Util

  def self.slack_name_for_city_name(city_name)
    city_name.downcase
        .gsub(' ', '-')
        .gsub('.', '_')
  end

  def self.city_name_for_slack_name(slack_name)
    slack_name
        .gsub('-', ' ')
        .gsub('_', '.')
        .split(/ |\_/)
        .map(&:capitalize).join(" ")
  end
end
