require 'sinatra'
require 'sinatra/activerecord'

class UserPrivilege < ActiveRecord::Base
  # fk user_id
  # power_user tinyint
  # admin_user tinyint
  belongs_to :user, dependent: :destroy

  def self.user_privs user, new_values = {}
    priv = UserPrivilege.where(user: user).first
    return [false, false] if !priv && new_values.empty?
    
    if !priv
      priv = UserPrivilege.new
    end
    
    if !new_values.empty?
      priv.power_user = !!new_values[:power_user] if new_values[:power_user]
      priv.admin_user = !!new_values[:admin_user] if new_values[:admin_user]
      priv.save!
    end
    
    return [!!priv.power_user, !!priv.admin_user]
  end
end
