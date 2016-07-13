require 'sinatra'
require 'sinatra/activerecord'

class UserPrivilege < ActiveRecord::Base
  def self.user_privs user_id, new_values = {}
    user = UserPrivilege.where(user_id: user_id).first
    return [false, false] if !user && new_values.empty?
    
    if !user
      user = UserPrivilege.new
      user.user_id = user_id
    end
    
    if !new_values.empty?
      user.power_user = new_values[:power_user] if new_values[:power_user]
      user.admin_user = new_values[:admin_user] if new_values[:admin_user]
      user.save!
    end
    
    return [user.power_user == 1, user.admin_user == 1]
  end
end
