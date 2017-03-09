require 'json'
require './pin'
require './chat'
require './user'

WEBHOOK_TOKEN = ENV['WEBHOOK_TOKEN']
PINS_URL = "https://slack.com/api/pins.list"
USER_INFO_URL = "https://slack.com/api/users.info"
REMOVE_URL = "https://slack.com/api/pins.remove"

class PinLogic
    def initialize(params)
        @channel_id = params[:channel_id]
        @channel_name = params[:channel_name]
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
                h[:author] = fetch_user(h[:author_id])
                h[:pinner] = fetch_user(h[:pinner_id])
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
                    pindb.author_id = pin[:author_id]
                    pindb.author_name = pin[:author_name]
                    pindb.pinner_id = pin[:pinner_id]
                    pindb.pinner_name = pin[:pinner_name]
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

    def fetch_user(id)
      user = User.with_user_id(id).first
      if !user
        response = remote_request USER_INFO_URL, user: id
        h = JSON.parse(response.body).to_h
        u = h['user']
        name = u == nil ? nil : u['name']
        user = User.new(user_name: name, user_id: id)
        user.save
        user
      else
        user
      end
    end

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
