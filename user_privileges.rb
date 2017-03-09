require 'sinatra'
require 'sinatra/activerecord'

class UserPrivilege < ActiveRecord::Base
  # fk user_id
  # power_user tinyint
  # admin_user tinyint
  belongs_to :user, dependent: :destroy

  def self.user_privs user, new_values = {}
    user = UserPrivilege.where(user: user).first
    return [false, false] if !user && new_values.empty?
    
    if !user
      user = UserPrivilege.new
    end
    
    if !new_values.empty?
      user.power_user = new_values[:power_user] if new_values[:power_user]
      user.admin_user = new_values[:admin_user] if new_values[:admin_user]
      user.save!
    end
    
    return [user.power_user == 1, user.admin_user == 1]
  end
end
