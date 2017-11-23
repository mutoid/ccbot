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
    @query = params[:text]
    @params = params
  end

  def quote
    # Rate limiting
    user = User.find_or_create(@params[:user_name], @params[:user_id])
    power_user, admin_user = UserPrivilege.user_privs(user)
    command = @params[:command]
    commands_by_user = RunCommand.where user: user, command: command
    puts "#{user.user_name} has run this command #{commands_by_user.size} times."
    # Fix Apple's fancy quotation marks
    @query.gsub!(/[\u201C\u201D]/,?")

    if commands_by_user.size > 0
      last_run = commands_by_user.last
      too_recent = last_run.created_at + 5.minutes > Time.now
      if too_recent && !power_user
        puts "#{user.user_name} last ran it too recently!"
        puts "Should not run"
        return "Try again in #{((last_run.created_at + 5.minutes) / 60.0).round(1)} minutes"
      end
    end

    new_command = RunCommand.new user: user, command: command
    new_command.save

    re = /@?(?<username>(?:[\w-]+|\*))?\s*(?<channel>#\w+)?\s*(?:(?:")(?<query>[^"]+)(?:"))?/

    arguments = match_to_h @query.match(re)

    pins = Pin.joins(:author)

    if arguments[:username] && arguments[:username] != 'random' && arguments[:username] != '*'
      author = User.named(arguments[:username]).first
      return "Can't find a user named #{arguments[:username]}" if !author
      pins = pins.all_quotes_by(author.user_name)
    end

    if arguments[:channel]
      chan_id = Pin.pluck(:channel_name, :channel_id).uniq.to_h[arguments[:channel].gsub(/#/,'')]
      return "No such channel exists" if !chan_id
      pins = pins.where(channel_id: chan_id)
    end

    if arguments[:query]
      pins = pins.where("text ILIKE ?", "%#{arguments[:query]}%")
    end

    pin = pins.sample
    return "No pins found" if !pin
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

  def remote_request(url, parameters)
    parameters = {token: WEBHOOK_TOKEN}.merge parameters
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(parameters)
    response = http.request(request)
  end

  def params
    @params
  end

  def match_to_h(match)
    Hash[match.names.map { |n| [n.to_sym, match[n]] }]
  end
end
