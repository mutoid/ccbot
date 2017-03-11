require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'
require './user.rb'

class Pin < ActiveRecord::Base
    # text: text
    # channel_id: string
    # channel_name: string
    # slack_timestamp: string
  belongs_to :author, class_name: User, foreign_key: :author_id
  belongs_to :pinner, class_name: User, foreign_key: :pinner_id

  scope :all_quotes_by, ->(user_name) { joins(:author).where("users.user_name = ?", user_name) }

  def to_s
    "#{self.author.user_name} '#{self.text}'"
  end

  def format
    ">#{self.text.gsub("\n", "\n>")}\n--_#{self.author.user_name}_"
  end
end
