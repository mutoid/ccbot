# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']

class BotLogic < Sinatra::Base
  get('/') do
    puts "Processing get / request"
    "I'm up."
  end

  post('/lenny') do
    puts "Processing /lenny command"
    # post response to $SLACK_DOMAIN$SLACKBOT_ENDPOINT$SLACKBOT_TOKEN
    response_text = "( ͡° ͜ʖ ͡°)"
    begin
      uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}")
      response = Net::HTTP.post_form(uri, {"token" => SLACKBOT_TOKEN, "data" => response_text })
      puts response
    rescue Exception => e
      logger.info "Got exception #{e}"
      puts "WTF!"
      raise e
    end
  end

  run! if app_file == $0
end
