module TourSlackBot
  module Commands
    class Events < SlackRubyBot::Commands::Base
      command 'events' do |client, data, match|

        client.say(channel: data.channel, text: "Here are the events:\n1\n2\n3\n\nSelect one now")

        client.on :message do |data|
        	puts "*** Events Response Data: #{data}\n#{data.text}"
        	case data.text
        	when '1' then
        		client.say(channel: data.channel, text: 'Great! You chose 1!')
        	when '2' then
						client.say(channel: data.channel, text: 'Awesome! You chose 2!')
        	when '3' then
						client.say(channel: data.channel, text: 'All right! You chose 3!')
					when 'events' then
						# To work around a Slack bug where 'events' gets set as the data
					else
						client.say(channel: data.channel, text: 'Sorry, you have to pick 1-3.')
        	end
        end
      end
    end
  end
end