require 'city_event_syncer'
require 'form_copy_apps_script_executor'
require 'channels_archiver'
require 'dotenv'

Dotenv.load

namespace :events do

  # Event Sync
  ################################################################  

  # Calls the Google Drive spreadsheet containing Events,
  # For each city, checks to see if we already have a TODO Form
  # and Responses sheet created for it. If we don't, creates it.
  #
  # This method is idempotent; If nothing to do, it will just be a no-op
  desc 'Syncs Events sheet, for each city, creates a TODO form and responses sheet if needed, creates a Slack channel if needed, and sets the TODO form as the topic in the Slack channel'
  task :sync do
    puts "Reading cities from the Events spreadsheet..."
    CityEventSyncer.update_sheet
    cities_hash = CityEventSyncer.get_cities
    if cities_hash and not cities_hash.empty?
      puts "Found #{cities_hash.keys[0]}..."
    else
      puts "Didn't find any cities."
    end
    slack_channels_hash = {}
    cities_hash.each do |city, value_list| # value_list is [FormURL, SheetURL]
      slack_channel_name = CityEventSyncer.slack_name_for_city_name(city)
      todo_form_url = value_list[0]
      slack_channels_hash[slack_channel_name] = todo_form_url
    end
    puts "Creating public Slack channels if they don't already exist..."
    CityEventSyncer.create_channels cities_hash.keys
    if cities_hash and not cities_hash.empty?
      puts "Created channels #{cities_hash.keys[0]}..."
    else
      puts "No channels to create."
    end
    channel_id_hash = CityEventSyncer.list_channels
    channel_todo_form_hash = {}
    channel_id_hash.each do |channel_name, id|
      todo_form_url = slack_channels_hash[channel_name]
      channel_todo_form_hash[id] = "#{CityEventSyncer::CITY_EVENT_SYNCER_TOPIC_PREFIX} #{todo_form_url}"
    end
    puts "Inviting the bot to the channels..."
    CityEventSyncer.channels_invite_bot channel_id_hash.values
    puts "Invited #{channel_id_hash.values[0]}..." if channel_id_hash and not channel_id_hash.empty?
    puts "Setting the Form as topic in Slack room if it's not already..."
    CityEventSyncer.channels_set_topics channel_todo_form_hash
    puts "Set topic #{channel_todo_form_hash.values[0]} in room #{channel_todo_form_hash.keys[0]}" if channel_todo_form_hash and not channel_todo_form_hash.empty?
  end

  desc 'Updates the Google sheet with formIDs and response destinations for each city'
  task :update_sheet do
    CityEventSyncer.update_sheet
  end

  desc 'Updates the Google Sheet with a new prefilled URL based on the latest responses of a given form'
  task :update_prefilled_url, :form_id do |t, args|
    formId = args[:form_id]
    raise "Can't update prefilled url without formId" if formId.empty?
    begin
      CityEventSyncer.update_sheet_with_updated_prefilled_url(formId)
    rescue Exception => e
      puts "Error updating sheet with prefilled url: #{e.backtrace}"
    end
  end

  desc 'Lists all the cities, forms, and response ids in the Events spreadsheet, in the format { "City Name" => "[FormID, ResponsesID]" }'
  task :get_cities do
    puts CityEventSyncer.get_cities
  end

  desc 'Lists all the channels in the Slack team'
  task :list_channels do
    puts CityEventSyncer.list_channels
  end

  desc 'Creates channels from a list of comma-separated channel_names'
  task :create_channels, :channel_names do |t, args|
    names = args[:channel_names].split(',')
    raise "Can't create channel names, channels empty" if names.empty?
    CityEventSyncer.create_channels names
  end

  # Archiving
  ################################################################

  desc 'Renames, archives, and leaves all channels'
  task :rename_archive_leave_channels do
    puts GroupsArchiver.rename_archive_and_leave_all_channels
  end

end