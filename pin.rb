require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'

class Pin < ActiveRecord::Base
    # author_id: string
    # author_name: string
    # pinner_id: string
    # pinner_name: string
    # text: text
    # channel_id: string
    # channel_name: string
    # slack_timestamp: string
  scope :all_quotes_by, ->(user_name) { where("author_name = ?", user_name)}

  def to_s
    "#{self.author_name} '#{self.text}'"
  end

  def format
    ">#{self.text}\n--_#{self.author_name}_"
  end
end
