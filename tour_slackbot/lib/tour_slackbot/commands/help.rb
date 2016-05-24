module TourSlackBot
  module Commands
    class Help < SlackRubyBot::Commands::Base
      command 'help' do |client, data, _match|
        client.say(channel: data.channel, text: "I'm here to help you get started with Brand New Congress! Send me a direct message to learn more!")
      end
    end
  end
end