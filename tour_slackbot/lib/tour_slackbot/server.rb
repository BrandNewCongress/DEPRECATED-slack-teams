module TourSlackBot
  class Server < SlackRubyBot::Server

    def initialize(attrs = {})
      puts "*** Initialized TourSlackBot ***"
    end

    on 'team_join' do |client, data|
      begin
        puts "*** New Joiner: #{data['user']['id']}"
        puts data.inspect

        msg = client.web_client.chat_postMessage(
          channel: data['user']['id'],
          text: "Hi <@#{data['user']['name']}>! Welcome to the BNC!",
          as_user: true)
      
      rescue Exception => e
        puts "Error messaging joined user: #{e}"
      end
    end
  end
end