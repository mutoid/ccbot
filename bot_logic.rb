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

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']
FAKE_RESPONSE = ENV['SINATRA_ENV'] != 'production'

# TODO: Put this in the database!
POWER_USERS = ["mutoid", "gaywallet"]
ADMIN_USERS = ["mutoid"]

class BotLogic < Sinatra::Base
  get('/') do
    puts "Processing get / request"
    "I'm up."
  end

  puts('/ruby') do
    puts "Evaluating Ruby code from the web, WCGW?"
    puts "Params: ", params
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user = ADMIN_USERS.include? user_name
    return "You don't have permission to do this dangerous action." if !ADMIN_USERS.include? user_name
    code = params[:command].sub(/^\/ruby /, '')

    # #YOLO dawg
    begin
      Timeout.timeout(10) do
        result = eval(code)
      end
    rescue StandardError => e
      return "There was an error: #{e.message}"
    end
    output =  "_#{user} ran the Ruby code: #{code}\n_"
    output << " => #{result.inspect}"
    puts "Result is #{result.inspect}"
    chat_out(message)
  end

  post('/lenny') do
    puts "Processing /lenny command"
    puts "Params: ", params

    # This is common logic and should get factored out if more commands get made.
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user = POWER_USERS.include? user_name
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

    chat_out(lenny)
  end

  run! if app_file == $0
end

def chat_out(message)
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
