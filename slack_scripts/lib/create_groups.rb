require 'dotenv'
require 'slack-ruby-client'
require 'google_drive'

Dotenv.load

EVENTS_CITIES_SHEET_INDEX = 1

module GroupCreator

	# Get all city names from our Google Spreadsheet
	def self.get_city_names
		cities_hash = {}
		session = GoogleDrive.saved_session("../../../google_drive_config.json")
		puts "getting spreadsheet...\n"
		begin
			sheet = session.spreadsheet_by_key(ENV['EVENTS_SPREADSHEET_ID'])
				.worksheets[EVENTS_CITIES_SHEET_INDEX]
			(2..sheet.num_rows).each do |row|
				city = sheet[row, 2]
				city_name = city.downcase.gsub(' ', '_').gsub('.', '')
				cities_hash[city] = city_name
			end
		rescue Exception => e
			puts "Exception: #{e}"
			puts "#{e.backtrace}"
		end

		cities_hash
	end

	# Create one private slack group for each city
	def self.create_groups(names)
		Slack.configure do |config|
			config.token = ENV['SLACK_API_TOKEN']
			fail "Missing ENV['SLACK_API_TOKEN']!" unless config.token
		end

		client = Slack::Web::Client.new(user_agent: 'Slack Ruby Client/1.0')
		names.each do |n|
			begin
				client.groups_create(name: n)
			rescue Exception => e
				puts "Error while creating channel for #{n}: #{e}"
				puts "#{e.backtrace}"
			end
		end
	end

	# Reads in 
	def self.update_sheet_with_new_forms_and_responses_ids(cities_hash)

	end
end

if __FILE__ == $0
	cities_hash = GroupCreator.get_city_names
	GroupCreator.create_groups(cities_hash.values.sort!)
	GroupCreator.update_sheet_with_new_forms_and_responses_ids(cities_hash)
end
