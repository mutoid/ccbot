# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'

SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']

logger = Logger.new('app.log', 10, 1024000)

class BotLogic < Sinatra::Base
  get('/') do
    logger.info "Processing get / request"
    "I'm up."
  end

  post('/lenny') do
    logger.info "Processing /lenny command"
    # post response to $SLACK_DOMAIN$SLACKBOT_ENDPOINT$SLACKBOT_TOKEN
    response_text = "( ͡° ͜ʖ ͡°)"
    begin
      uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}")
      response = Net::HTTP.post_form(uri, {"token" => SLACKBOT_TOKEN, "data" => response_text })
    rescue Exception => e
      logger.info "Got exception #{e}"
      raise e
    end
  end

  run! if app_file == $0
end
