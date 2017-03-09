require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'

class User < ActiveRecord::Base
  # user_id: string
  # user_name: string
  
  belongs_to :pin
  belongs_to :run_command
  belongs_to :user_privilege

  scope :named, ->(name) { where("user_name = ?", user_name) }
  scope :with_user_id, ->(user_id) { where("user_id = ?", user_id) }
  scope :active_within, ->(duration) { where("updated_at > ?", duration.ago) }
  
  def ==(other)
    user_id == other.user_id
  end

  def eql?(other)
    self == other
  end

  def hash
    user_id.hash
  end
end
