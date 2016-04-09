# coding: utf-8
# -*- coding: utf-8 -*-

require 'net/http'
require 'uri'
require 'json'
require './chat'
require './user_privs'

GIFME_API_KEY = ENV['GIFME_API_KEY']

class GifmeLogic
  def self.html5_link(url)
    return url.sub(/\.gif$/, '.gifv') if url.include? 'imgur'
    return url.sub(/[^.]*\.(gfycat.com\/.*)\.gif/, 'https://\1') if url.include? 'gfycat'
    url
  end

  def self.process(params, sfw=true)
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = UserPrivilege.user_privs(user_id)
    command = params[:command]
    terms = params[:text]
    query_string = terms.gsub(' ','+')

    new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
    new_command.save

    ### DO EXTERNAL REQUEST ###
    uri = URI.parse("http://api.gifme.io/v1/search?key=#{GIFME_API_KEY}&sfw=#{sfw}&limit=10&query=#{query_string}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    ###

    results = JSON.parse response.body
    puts results
    puts results["meta"]
    return "No gifme.io results found for '#{terms}'" if results["meta"]["total"] == 0

    image_url = results["data"].sample()["link"]
    final_url = html5_link image_url

    print image_url
    print " => #{final_url}" if final_url != image_url
    print "\n"

    Chat.new(channel).chat_out "_#{user_name} searched gifme.io for '#{terms}':_\n#{final_url}"
  end
end
