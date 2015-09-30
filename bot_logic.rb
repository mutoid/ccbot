# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']

class BotLogic < Sinatra::Base
  post('/lenny') do
    # post response to $SLACK_DOMAIN$SLACKBOT_ENDPOINT$SLACKBOT_TOKEN
    response_text = "( ͡° ͜ʖ ͡°)"
    uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}")
    response = Net::HTTP.post_form(uri, {"token" => SLACKBOT_TOKEN, "data" => response_text })
  end

  run! if app_file == $0
end
