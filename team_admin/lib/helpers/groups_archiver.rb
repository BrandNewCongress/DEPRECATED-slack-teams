require 'slack-ruby-client'
require './lib/utils/configure_clients'

Dotenv.load

module GroupsArchiver
	extend ConfigureClients

	def self.archive_all_groups
		client = configure_slack
		groups = client.groups_list()['groups'] || []
		if groups.empty?
			puts "No groups to archive"
			return
		end
		groups.each do |g|
			begin
				puts "Renaming #{g.name} to #{g.name}_archived"
				client.groups_archive(channel: g.id)
			rescue Exception => e
				puts "Error: #{e}\nGroup: #{g}"
			end
		end
	end

	def self.rename_archived_groups
		client = configure_slack
		groups = client.groups_list()['groups'] || []
		groups.reject! { |g| g["is_archived"] == false }
		if groups.empty?
			puts "No archived groups to rename"
			return
		end
		groups.each do |g|
			begin
				puts "Renaming #{g.name} to #{g.name}_archived"
				client.groups_rename(channel: g.id, name: "#{g.name}_archived2")
			rescue Exception => e
				puts "Error: #{e}\nGroup: #{g}"
			end
		end
	end

	def self.leave_archived_groups
		client = configure_slack
		groups = client.groups_list()['groups'] || []
		groups.reject! { |g| g["is_archived"] == false }
		groups.each do |g|
			puts "Group #{g.name}"
			begin
				puts "Leaving Group #{g.name}"
				client.groups_leave(channel: g.id)
			rescue Exception => e
				puts "Error: #{e}\nGroup: #{g}"
			end
		end
	end
end

if __FILE__ == $0
	# GroupsArchiver.archive_all_groups
	# GroupsArchiver.rename_archived_groups
	# GroupsArchiver.leave_archived_groups
end