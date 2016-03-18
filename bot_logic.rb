# coding: utf-8

# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'sinatra'
require 'sinatra/activerecord'
require './environments'

class RunCommand < ActiveRecord::Base
end

class UserPrivilege < ActiveRecord::Base
end

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']
FAKE_RESPONSE = ENV['SINATRA_ENV'] != 'production'

class BotLogic < Sinatra::Base
  get('/') do
    puts "Processing get / request"
    "I'm up."
  end

  post('/ruby') do
    puts "Evaluating Ruby code from the web, WCGW?"
    puts "Params: ", params
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = user_privs(user_id)
    return "You don't have permission to do this." if !admin_user
    code = params[:text]

    # #YOLO dawg
    result = nil
    begin
      Timeout.timeout(10) do
        result = eval(code)
      end
    rescue SyntaxError => se
      return "There was a syntax error in #{code} #{se.message}"
    rescue StandardError => e
      return "There was an error: #{e.message}"
    end
    output =  "_#{user_name} ran some Ruby code:_\n```#{code}```\n"
    output << "``` => #{result}```"
    puts "Result is #{result}"
    chat_out(output, channel)
  end

  post('/lenny') do
    puts "Processing /lenny command"
    puts "Params: ", params

    # This is common logic and should get factored out if more commands get made.
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = user_privs(user_id)
    command_parts = params[:command].split(' ')
    command = command_parts.first

    lennys = ["( ͡° ͜ʖ ͡°)",
              "( ͡o ͜ʖ ͡o)",
              "ᕦ( ͡° ͜ʖ ͡°)ᕤ You did it!",
              "( ͠° ͟ʖ ͡°)"]

    commands_by_user = RunCommand.where user_id: user_id, command: command
    puts "#{user_name} has run this command #{commands_by_user.size} times."

    if commands_by_user.size > 0
      last_lenny = commands_by_user.last
      break "Wait a bit, will ya?" if last_lenny.created_at + 1.minute > Time.now && !power_user
    end

    new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
    new_command.save

    lenny_count = RunCommand.where("created_at >= ?", Time.now - 10.seconds).count
    puts "recent lenny count = #{lenny_count}"
    lenny_index = [lenny_count - 1, lennys.count - 1].min
    lenny = lennys[lenny_index]

    if FAKE_RESPONSE
      puts "#{user_name} did a lenny."
      break lenny
    end

    chat_out(lenny, channel)
  end

  run! if app_file == $0
end

def chat_out(message, channel)
  begin
    uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}?token=#{SLACKBOT_TOKEN}&channel=#{channel}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request.body = message
      response = http.request(request)
      
      puts response
      puts response.body
  rescue StandardError => e
    logger.info "Got exception #{e}"
    puts "WTF!"
    raise e
  end
end

def count_to_lenny(count, report_width, max_bar)
  lenny_full = '( ͡° ͜ʖ ͡°)'
  lenny_2_3 = '( ͡° ͜ʖ'
  lenny_1_3 = '( ͡°'
  lennies = (report_width * count / max_bar)
  whole_lennies = lennies.to_i
  remainder = lennies - whole_lennies
  lenny_full * lennies + (remainder > 0.66 ? lenny_2_3 : (remainder > 0.33 ? lenny_1_3 : ""))
end

def lenny_graph(report_width=12.0)
  report_width = report_width.to_f
  total_count = RunCommand.count
  name_length = RunCommand.pluck(:user_name).uniq.map(&:length).max + 1
  report = RunCommand.where(command: '/lenny').map { |x| [x.user_id, x.user_name] }.group_by(&:first).map { |k, v| [v.first.last, v.count] }
  max_bar = report.max_by { |name, count| count }.last
  name_format_string = "%-#{name_length}.#{name_length}s"
  lenny_scale = (max_bar / report_width).round(2)
  report.sort_by(&:last).reverse!.map { |name, count| "#{name_format_string % name}|#{count_to_lenny(count, report_width, max_bar)}" }.unshift("THE LENNY GRAPH: ( ͡° ͜ʖ ͡°) = #{lenny_scale} runs of the /lenny command" + "\n").join("\n")
end

def ascii_to_fullwidth s
  wide_map = Hash[(0x21..0x7F).map { |x| [x, x + 0xFEE0] }]
  wide_map[0x20] = 0x3000 # space
  wide_map[0x22] = 0x309B # quote
  wide_map[0x2C] = 0x3001 # comma
  wide_map[0x2D] = 0x30FC # minus
  wide_map[0x2E] = 0x3002 # period
  wide_map[0x3C] = 0x3008 # LT
  wide_map[0x3E] = 0x3009 # GT
  wide_map[0x3F] = 0xFF1F # question mark
  wide_map[0x60] = 0x2018 # grave accent

  s.each_char.to_a.map { |c| wide_map[c.ord] || c.ord }.pack('U*')
end

def cross_word s
  a = ascii_to_fullwidth(s.upcase).each_char.to_a
  "\n" + (a[1..-1].unshift(a.join(" "))).join("\n")
end

def square_word s
  a = ascii_to_fullwidth(s.upcase).each_char.to_a
  "\n" + Array.new(a.length) { |i| a.rotate(i).join(" ") }.join("\n")
end

def random_user
  "Randomly-selected user who has run /lenny is: #{RunCommand.all.uniq { |x| x.user_id }.map(&:user_name).sample}"
end

def user_privs user_id
  user = UserPrivilege.where(user_id: user_id).first
  return [false, false] if !user
  return [user.power_user, user.admin_user]
end
