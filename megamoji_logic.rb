# coding: utf-8
# -*- coding: utf-8 -*-

require './chat'
require './user_privileges'

class MegamojiLogic
  def self.define_megamoji(base_name, width, count)
    return Megamoji.create_or_update(base_name, width, count)
  end

  def self.delete_megamoji(base_name)
    return Megamoji.delete(base_name)
  end
  
  def self.process(params)
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    user = User.find_or_create(user_name, user_id)
    power_user, admin_user = UserPrivilege.user_privs(user)
    terms = params[:text]
    command = params[:command]
    return "You need to specify an emoji, dummy!" if !terms.match(/\w+/)
    base_name = terms[/\w+/]
    
    commands_by_user = RunCommand.where user: user, command: command
  
    if commands_by_user.size > 0
      last_megamoji = commands_by_user.last
      too_recent = last_megamoji.created_at + 1.hour > Time.now
      puts "#{user_name} last ran it too recently!" if too_recent
      puts "Should not megamoji" if too_recent && !power_user
      return "The impact of megamoji is in their rarity." if too_recent && !power_user
    end

    emoji = Megamoji.megamoji(base_name)
    return "No entry added for '#{base_name}'" if !emoji

    out_string = [*(1..emoji.count)].each_slice(emoji.width).map { |a|  a.map { |n| ":#{base_name}#{n}:" }.join }.join "\n"

    new_command = RunCommand.new user: user, command: command
    new_command.save

    if FAKE_RESPONSE
      puts "#{user_name} did megamoji #{param}."
      return out_string
    end

    Chat.new(channel).chat_out(out_string)
  end
end
