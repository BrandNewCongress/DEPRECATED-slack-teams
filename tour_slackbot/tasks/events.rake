require 'city_event_syncer'
require 'form_copy_apps_script_executor'

namespace :events do

	# Calls the Google Drive spreadsheet containing Events,
	# For each city, checks to see if we already have a TODO Form
	# and Responses sheet created for it. If we don't, creates it.
	#
	# This method is idempotent; If nothing to do, it will just be a no-op
	desc 'Syncs Events sheet, for each city, creates a TODO form and responses sheet if needed, creates a Slack channel if needed, and sets the TODO form as the topic in the Slack channel'
	task :sync do
		CityEventSyncer.update_sheet

		# Create private Slack Groups if they don't already exist
		# group_names = cities_hash.keys.sort!.map do |c|
		# 	slack_name_for_city_name(c)
		# end
		# puts "Creating Private Slack Groups for:\n#{group_names}"
		# create_groups(group_names)
		cities_hash = CityEventSyncer.get_cities
		slack_groups_hash = {}
		cities_hash.each do |city, value_list| # value_list is [FormURL, SheetURL]
			slack_group_name = CityEventSyncer.slack_name_for_city_name(city)
			todo_form_url = value_list[0]
			slack_groups_hash[slack_group_name] = todo_form_url
		end

		CityEventSyncer.create_groups cities_hash.keys
		group_id_hash = CityEventSyncer.list_groups
		group_todo_form_hash = {}
		group_id_hash.each do |group_name, id|
			todo_form_url = slack_groups_hash[group_name]
			group_todo_form_hash[id] = "Click here to update your progress: #{todo_form_url}"
		end
		# Set Google Form as topic in Slack room if it's not already
		CityEventSyncer.groups_set_topics group_todo_form_hash
	end

	desc 'Lists all the cities, forms, and response ids in the Events spreadsheet, in the format { "City Name" => "[FormID, ResponsesID]" }'
	task :get_cities do
		CityEventSyncer.get_cities
	end

	desc 'Lists all the private groups in the Slack team'
	task :list_groups do
		CityEventSyncer.list_groups
	end

	desc 'Creates groups from a list of comma-separated group_names'
	task :create_groups, :group_names do |t, args|
		names = args[:group_names].split(',')
		raise "Can't create group names, groups empty" if names.empty?
		CityEventSyncer.create_groups names
	end

end