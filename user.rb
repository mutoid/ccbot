require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'

WEBHOOK_TOKEN = ENV['WEBHOOK_TOKEN']
USER_INFO_URL = "https://slack.com/api/users.info"

class User < ActiveRecord::Base
  # user_id: string
  # user_name: string
  
  belongs_to :pin
  belongs_to :run_command
  belongs_to :user_privilege

  scope :named, ->(name) { where("user_name = ?", name) }
  scope :with_user_id, ->(id) { where("user_id = ?", id) }
  scope :active_within, ->(duration) { where("updated_at > ?", duration.ago) }

  def self.find_or_create(user_name, user_id)
    user = with_user_id(user_id).first
    if !user
      user = User.new(user_name: user_name, user_id: user_id)
      user.save!
    end
    user
  end

  def self.fetch_by_user_id(user_id)
    user = with_user_id(user_id).first
    user = fetch_user(user_id) if !user
  end
  
  def ==(other)
    user_id == other.user_id
  end

  def eql?(other)
    self == other
  end

  def hash
    user_id.hash
  end

  private

  def self.fetch_user(id)
    response = remote_request USER_INFO_URL, user: id
    h = JSON.parse(response.body).to_h
    u = h['user']
    name = u == nil ? nil : u['name']
    user = User.new(user_name: name, user_id: id)
    user.save
    user
  end

  def self.remote_request(url, params)
      params = {token: WEBHOOK_TOKEN}.merge params
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
      response = http.request(request)
  end
end
