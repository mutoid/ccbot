# coding: utf-8
# -*- coding: utf-8 -*-

require './chat'
require './user_privs'

class GifmeLogic
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

    # DO EXTERNAL REQUEST
    uri = URI.parse("http://api.gifme.io/v1/search?key=#{GIF_ME_API_KEY}&nsfw=true&limit=20&query=#{query_string}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request.body = message
    response = http.request(request)

    results = JSON.parse response
    image_url = results[:data].sample()[:link]

    puts image_url

    return image_url
  end
end

