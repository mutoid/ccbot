# coding: utf-8
# -*- coding: utf-8 -*-

require 'net/http'
require 'uri'
require 'json'
require 'resolv-replace'
require './chat'
require './user_privs'

LASTFM_API_KEY = ENV['LASTFM_API_KEY']

class LastfmLogic
  def self.process(params)

    channel = params[:channel_id]
    channel_name = params[:channel_name]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = UserPrivilege.user_privs(user_id)
    command = params[:command]
    terms = params[:text]

    if terms.match(/\w+,\w+/)
      user_string1 = terms.match(/(\w+,)/)
      user_string2 = terms.match(/\w+, (\w+)/)

      new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
      new_command.save
      begin
        lastfm_search_compare(user_string1, user_string2)
      rescue Exception => e
        return e.message + "terms used: '#{terms}'"
      end
    else
      #Get user recent track
      new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
      new_command.save

      begin
        lastfm_search_recent(terms)
      rescue Exception => e
        return e.message + "terms used: '#{terms}'"
      end
    end
  end

  def self.lastfm_search_recent(user_string)
    ### DO EXTERNAL REQUEST ###
    uri = URI.parse("http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{user_string}&api_key=#{LASTFM_API_KEY}&format=json&limit=1")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    ###

    results = JSON.parse response.body

    if results['error']
      raise "Something went terribly, terribly wrong and you shouldn't blame Alpaca for sure"
    end

    track = results['recenttracks']['track'][0]
    if !track
      raise "You haven't listened to any tracks on last.fm you dumbass. Connect your spotify."
    end

    #Gets dat song info
    artist = track['artist']['#text']
    name = track['name']
    album = track['album']['#text']
    image = track['image'][2] #selects the medium size

    puts "_#{user_name} last listened to _#{name}_ by #{artist} on the album _#{album}_: #{image}"
  end

  def self.lastfm_search_compare(user_string1, user_string2)
    ### DO BOTH EXTERNAL REQUESTS ###
    uri1 = URI.parse("http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=#{user_string1}&api_key=#{LASTFM_API_KEY}&format=json&limit=100")
    http1 = Net::HTTP.new(uri1.host, uri1.port)
    http1.use_ssl = false
    request1 = Net::HTTP::Get.new(uri1)
    response1 = http.request(request1)

    uri2 = URI.parse("http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=#{user_string2}&api_key=#{LASTFM_API_KEY}&format=json&limit=100")
    http2 = Net::HTTP.new(uri2.host, uri2.port)
    http2.use_ssl = false
    request2 = Net::HTTP::Get.new(uri2)
    response2 = http.request(request2)
    ###

    results1 = JSON.parse response1.body
    results2 = JSON.parse response2.body

    if results1['error'] || results2['error']
      raise "Something went terribly, terribly wrong and you shouldn't blame Alpaca for sure"
    end

    union = results1['topartists']['artist'] & results2['topartists']['artist']
    size_of_union = union.size
    size_of_large = [results1['topartists']['artist'].size, results2['topartists']['artist']].max
    percentage = size_of_union / size_of_large

    puts "_#{user_string1} and #{user_string2} have a #{percentage} artist overlap. Top shared artists: [#{union[0]}, #{union[1]}, #{union[2]} ]"
  end
end
