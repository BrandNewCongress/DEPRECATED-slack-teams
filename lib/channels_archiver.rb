require 'slack-ruby-client'
require 'utils/configure_clients'
require 'dotenv'

Dotenv.load

module GroupsArchiver
  extend ConfigureClients

  def self.archive_all_channels
    client = configure_slack
    channels = client.channels_list()['channels'] || []
    if channels.empty?
      puts "No channels to archive"
      return
    end
    channels.each do |c|
      begin
        puts "Archiving #{c.name}"
        client.channels_archive(channel: c.id)
      rescue Exception => e
        puts "Error: #{e}\nGroup: #{c}"
      end
    end
  end

  def self.rename_archived_channels
    client = configure_slack
    channels = client.channels_list()['channels'] || []
    channels.reject! { |c| c["is_archived"] == false }
    if channels.empty?
      puts "No archived channels to rename"
      return
    end
    channels.each do |c|
      begin
        puts "Renaming #{c.name} to #{c.name}_archived"
        client.channels_rename(channel: c.id, name: "#{c.name}_archived2")
      rescue Exception => e
        puts "Error: #{e}\nGroup: #{c}"
      end
    end
  end

  def self.leave_archived_channels
    client = configure_slack
    channels = client.channels_list()['channels'] || []
    channels.reject! { |c| c["is_archived"] == false }
    channels.each do |c|
      puts "Group #{c.name}"
      begin
        puts "Leaving Group #{c.name}"
        client.channels_leave(channel: c.id)
      rescue Exception => e
        puts "Error: #{e}\nGroup: #{c}"
      end
    end
  end

  def self.rename_archive_and_leave_all_channels
    client = configure_slack
    channels = client.channels_list()['channels'] || []
    channels.reject! { |c| c["is_archived"] == true }
    if channels.empty?
      puts 'No channels to rename, archive, or leave'
      return
    end
    channels.each do |c|
      begin
        puts "*** Renaming #{c.name} to #{c.name}_archived"
        client.channels_rename(channel: c.id, name: "#{c.name}_archived")
        puts "*** Archiving #{c.name}_archived"
        client.channels_archive(channel: c.id)
        puts "*** Leaving Group #{c.name}"
        client.channels_leave(channel: c.id)
      rescue Exception => e
        puts "Error: #{e}\nGroup: #{c}"
      end
    end
  end
end

if __FILE__ == $0
  # GroupsArchiver.archive_all_channels
  # GroupsArchiver.rename_archived_channels
  # GroupsArchiver.leave_archived_channels
end