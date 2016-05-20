require 'sinatra'
require 'sinatra/activerecord'

# Columns: base_name, width, count

class Megamoji < ActiveRecord::Base
  def self.megamoji 
    emoji = Megamoji.where(base_name: base_name).first
    return nil if emoji.nil?
    return emoji
  end

  def self.create_or_update(base_name, width, count)
    emoji = Megamoji.where(base_name: base_name).first || Megamoji.new(base_name, width, count)
    emoji.width = width
    emoji.count = count
    emoji.save!
  end

  def self.delete(base_name)
    emoji = Megamoji.where(base_name: base_name).first
    emoji.delete
  end
end
