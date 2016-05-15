require 'google_drive'

class Event < ActiveRecord::Base

	# Class variable shared between all Event instances
	@@gd_session = GoogleDrive.saved_session("../google_drive_config.json")

	class << self

		def initialize
			puts "*** self.initialize"
		end

		def find_or_create_by_title(title)
			event = Event.find_or_initialize_by(title: title)
			if event.new_record?
				# New event
				# Create new google form for it
				s = @@gd_session.create_spreadsheet("#{title.capitalize} BNC Spreadsheet")
				event.spreadsheet_key = s.key
				event.save!
			else
				# Old event
			end

			event
		end
	end

end