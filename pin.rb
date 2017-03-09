require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'
require './user.rb'

class Pin < ActiveRecord::Base
    # text: text
    # channel_id: string
    # channel_name: string
    # slack_timestamp: string
  has_one :author, class_name: User, foreign_key: :author_id, dependent: :nullify
  has_one :pinner, class_name: User, foreign_key: :pinner_id, dependent: :nullify

  scope :all_quotes_by, ->(user_name) { joins("inner join users on users.user_id = pins.author_id").where("users.user_name = ?", user_name) }

  def to_s
    "#{self.author_name} '#{self.text}'"
  end

  def format
    ">#{self.text}\n--_#{self.author_name}_"
  end
end
