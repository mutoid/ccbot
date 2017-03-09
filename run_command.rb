require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'

class RunCommand < ActiveRecord::Base
      # fk user_id
      # string command
    has_one :user, dependent: :nullify
end
