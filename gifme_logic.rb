# coding: utf-8
# -*- coding: utf-8 -*-

require 'net/http'
require 'uri'
require 'json'
require 'resolv-replace'
require './chat'
require './user_privileges'

GIFME_API_KEY = ENV['GIFME_API_KEY']

class GifmeLogic
  def self.html5_link(url)
    url = url.sub(' ', '%20')
    return url.sub(/\.gif$/, '.gifv') if url.include? 'imgur'
    return url.sub(/[^.]*\.(gfycat.com\/.*)(\.gif|\.webm)/, 'https://\1') if url.include? 'gfycat'
    url
  end

  def self.process(params)
    channel = params[:channel_id]
    channel_name = params[:channel_name]
    user_name = params[:user_name]
    user_id = params[:user_id]
    user = User.find_or_create(user_name, user_id)
    power_user, admin_user = UserPrivilege.user_privs(user)
    command = params[:command]
    terms = params[:text]
    query_string = terms.gsub(' ','+')
    sfw = !channel_name.downcase.include?('nsfw')

    new_command = RunCommand.new user: user, command: command
    new_command.save

    begin
      final_url = gifme_search(query_string, sfw)
    rescue Exception => e
      return e.message + "terms used: '#{terms}'"
    end

    puts "_#{user_name} searched gifme.io for '#{terms}' #{'(nsfw ok)' if !sfw}:_\n#{final_url}"
    Chat.new(channel).chat_out "_#{user_name} searched gifme.io for '#{terms}' #{'(nsfw ok)' if !sfw}:_\n#{final_url}"
  end

  def self.gifme_search(query_string, sfw)
    ### DO EXTERNAL REQUEST ###
    uri = URI.parse("http://api.gifme.io/v1/search?key=#{GIFME_API_KEY}&sfw=#{sfw ? 'true' : 'false' }&limit=20&query=#{query_string}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    ###

    results = JSON.parse response.body

    puts results["meta"]
    results['data'].keep_if { |result| result['score'] <= 10 }
    results['data'].delete_if { |result| result['link'] =~ /\.jpe?g$/i }
    puts results
    raise "No gifme.io results found" if results["data"].size == 0

    images = results['data'].first(10).map { |data| data['link'] }.shuffle
    while ((image_url = images.pop))
      puts "Trying #{image_url}..."
      ### ANOTHER EXTERNAL REQUEST ###
      uri = URI.parse(image_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = false
      response = http.request_head(uri)
      ###
      if response.code.to_i != 200
        puts "Throwing out broken link #{image_url} (response code: #{response.code})"
        next
      end
      break
    end
    raise "gifme.io results all had broken links.  Sorry." if !image_url
    final_url = html5_link image_url

    print image_url
    print " => #{final_url}" if final_url != image_url
    print "\n"
    final_url
  end
end
