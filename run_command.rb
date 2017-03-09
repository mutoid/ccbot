require 'sinatra/base'
require 'sinatra'
require 'sinatra/activerecord'

class RunCommand < ActiveRecord::Base
      # fk user_id
      # string command
    belongs_to :user, dependent: :nullify
end
