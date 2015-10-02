# coding: utf-8

# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'
require 'sinatra'
require 'sinatra/activerecord'
require './environments'

class RunCommand < ActiveRecord::Base
end

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']
FAKE_RESPONSE = ENV['SINATRA_ENV'] != 'production'

POWER_USERS = ["mutoid", "gaywallet"]

class BotLogic < Sinatra::Base
  get('/') do
    puts "Processing get / request"
    "I'm up."
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
              "ᕦ( ͡° ͜ʖ ͡°)ᕤ You did it!"]

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
    lenny_index = [lenny_count - 1, 2].min
    lenny = lennys[lenny_index]

    if FAKE_RESPONSE
      puts "#{user_name} did a lenny."
      break lenny
    end

    begin
      uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}?token=#{SLACKBOT_TOKEN}&channel=#{channel}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request.body = lenny
      response = http.request(request)

      puts response
      puts response.body
    rescue Exception => e
      logger.info "Got exception #{e}"
      puts "WTF!"
      raise e
    end
  end

  run! if app_file == $0
end
