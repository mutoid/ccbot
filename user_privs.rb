require 'sinatra'
require 'sinatra/activerecord'

class UserPrivilege < ActiveRecord::Base
  def self.user_privs user_id
    user = UserPrivilege.where(user_id: user_id).first
    return [false, false] if !user
    return [user.power_user, user.admin_user]
  end
end
