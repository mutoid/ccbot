# coding: utf-8
# -*- coding: utf-8 -*-

require 'net/http'
require 'uri'
require 'json'
require './chat'
require './user_privs'

GIFME_API_KEY = ENV['GIFME_API_KEY']

class GifmeLogic
  def html5_link(url)
    return url.sub(/\.gif$/, '.gifv') if url.include? 'imgur'
    return url.gsub(/.*\.(gfycat.com\/.*)\.gif/, "#{$1}") if url.include? '.gfycat'
    url
  end

  def self.process(params)
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = UserPrivilege.user_privs(user_id)
    command_parts = params[:command].split(' ')
    command = command_parts.first
    query_string = command_parts[1..-1].join '+'

    new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
    new_command.save

    ### DO EXTERNAL REQUEST ###
    uri = URI.parse("http://api.gifme.io/v1/search?key=#{GIFME_API_KEY}&nsfw=false&limit=20&query=#{query_string}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    ###

    results = JSON.parse response.body
    image_url = results["data"].sample()["link"]

    Chat.new(channel).chat_out(html5_link image_url)
  end
end

