require 'json'
require './pin'
require './chat'
require './user'

WEBHOOK_TOKEN = ENV['WEBHOOK_TOKEN']
PINS_URL = "https://slack.com/api/pins.list"
REMOVE_URL = "https://slack.com/api/pins.remove"

class PinLogic
    def initialize(params)
        @channel_id = params[:channel_id]
        @channel_name = params[:channel_name]
        @args = params[:text]
    end

    def quote
      author = User.named(@args.split.first).first
      return "No pinned quotes by such a user" if !author
      pin = Pin.all_quotes_by(author.user_name).sample
      Chat.new(@channel_id).chat_out(pin.format)
    end

    def pins_list
        puts "Getting pin list..."
        begin
            response = remote_request PINS_URL, channel: @channel_id
            h = JSON.parse(response.body).to_h
            puts h
            messages = h['items'].select { |i| i['type'] == 'message' }.map { |m|
              { author_id: m['message']['user'],
                pinner_id: m['created_by'],
                text: m['message']['text'],
                ts: m['message']['ts']
              }
            }
            messages.map do |h|
                h[:author] = User.fetch_by_user_id(h[:author_id])
                h[:pinner] = User.fetch_by_user_id(h[:pinner_id])
        end
        rescue Exception => e
            puts "Hook operation failed because #{e.message}"
        end
        messages
    end

    def remove_all_pins
        Thread.new do
            sleep(1)
            Chat.new(@channel_id).chat_out("Deleting #{pins_list.count} pins from #{@channel_name} and saving to DB!")
            pins_list.each do |pin|
                begin
                    puts "Saving pin ..."
                    pindb = Pin.new
                    pindb.author = pin[:author]
                    pindb.pinner = pin[:pinner]
                    pindb.text = pin[:text]
                    pindb.channel_id = @channel_id
                    pindb.channel_name = @channel_name
                    pindb.slack_timestamp = pin[:ts]
                    pindb.save!
                rescue Exception => e
                    puts "DB operation failed for pin #{pin} because #{e.message}"
                    next # Don't delete the pin in the code below!
                end

                begin
                    remove_pin(@channel_id, pin[:ts])
                rescue Exception => e
                    puts "Remote operation failed for pin #{pin} because #{e.message}"
                end
            end
        end
        "Consider it done."
    end

    private

    def remove_pin(channel, timestamp)
        remote_request REMOVE_URL, channel: channel, timestamp: timestamp
    end

    def remote_request(url, params)
        params = {token: WEBHOOK_TOKEN}.merge params
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(params)
        response = http.request(request)
    end
end
