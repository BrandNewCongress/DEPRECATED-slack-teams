require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'
require './lib/utils/configure_clients'

Dotenv.load

EVENTS_CITIES_SHEET_INDEX = 0
EVENTS_TODO_FORM_CITY_INDEX = 2
EVENTS_TODO_FORM_COL_INDEX = 7
EVENTS_TODO_RESPONSES_COL_INDEX = 8

module CityEventSyncer
	extend ConfigureClients

	# Calls the Google Drive spreadsheet containing Events,
	# For each city, checks to see if we already have a TODO Form
	# and Responses sheet created for it. If we don't, creates it.
	#
	# This method is idempotent; If nothing to do, it will just be a no-op
	def self.sync_sheet
		# Get all cities from the Google Spreadsheet for Events
		puts 'Getting all cities from the Google Events Spreadsheet'
		cities_hash = get_cities
		puts cities_hash

		# Create Google Form per-city if it doesn't already exist, add to sheet


		# Create Google Responses Spreadsheet per-city if it doesn't already exist, add to sheet


		# Create private Slack Groups if they don't already exist
		# group_names = cities_hash.keys.sort!.map do |c|
		# 	slack_name_for_city_name(c)
		# end
		# puts "Creating Private Slack Groups for:\n#{group_names}"
		# create_groups(group_names)

		# Set Google Form as topic in Slack room if it's not already


	end

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
				todo_form = sheet[row, EVENTS_TODO_FORM_COL_INDEX]
				responses_sheet = sheet[row, EVENTS_TODO_RESPONSES_COL_INDEX]
				cities_hash[city] = [todo_form, responses_sheet]
			end
		rescue Exception => e
			puts "Exception: #{e}"
			puts "#{e.backtrace}"
		end

		cities_hash
	end

	# Create one private slack group for each city
	# Returns all private Slack groups names
	def self.create_groups(group_names)
		client = configure_slack
		group_names.each do |n|
			begin
				client.groups_create(name: n)
			rescue Exception => e
				puts "Error while creating channel for #{n}: #{e}"
				puts "#{e.backtrace}"
			end
		end
	end

	# Returns all groups in the format { "GroupName" => "GroupID"}
	def self.list_groups
		client = configure_slack
		begin
			groups = client.groups_list(exclude_archived: true)['groups'] || []
		rescue Exception => e
			puts "Error while getting groups list: #{e}"
			puts "#{e.backtrace}"
		end

		groups.map { |g| { g.name => g.id } }
	end

	def self.groups_set_topics(group_id_to_topic_hash)
		client = configure_slack
		group_id_to_topic_hash.each do |gid, t|
			begin
				topic = group_get_topic(gid)
				client.groups_setTopic(channel: gid, topic: t) unless topic == t
			rescue Exception => e
				puts "Error while setting topic: #{e}\nGroup: #{gid}\nTopic: #{t}"
				puts "#{e.backtrace}"
			end
		end
	end

	def self.group_get_topic(group_id)
		client = configure_slack
		begin
			t = client.groups_info(channel: group_id)['group']['topic']['value']
		rescue Exception => e
			puts "Error while getting group topic: #{e}\nGroup: #{group_id}"
			puts "#{e.backtrace}"
		end
		t
	end

	private

	def self.slack_name_for_city_name(city_name)
		city_name.downcase.gsub(' ', '_').gsub('.', '')
	end
end
