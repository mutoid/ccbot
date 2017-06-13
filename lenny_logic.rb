# coding: utf-8
# -*- coding: utf-8 -*-

require './chat'
require './user_privileges'

FAKE_RESPONSE = ENV['SINATRA_ENV'] != 'production'

class LennyLogic
   LENNYS = ["( ͡° ͜ʖ ͡°)",
             "( ͡o ͜ʖ ͡o)",
             "ᕦ( ͡° ͜ʖ ͡°)ᕤ You did it!",
             "( ͠° ͟ʖ ͡°)"]

   SPOOKED_LENNYS = ["(◔ д◔) ｓｐｏｏｋｅｄ！",
                     "ᕕ༼ •́ Д •̀ ༽ᕗ *SUPER SPOOKED*!",
                     "ᕦ⊙෴⊙ᕤ :doot: *ＳＰＯＯＫＹ　ＤＯＯＴＳ!* :doot:",
                     "/╲/( ͡° ͡° ͜ʖ ͡° ͡°)/\\╱\\ That's enough spookin'"]

  def self.process(params)
    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    user = User.find_or_create(params[:user_name], params[:user_id])
    power_user, admin_user = UserPrivilege.user_privs(user)
    command = params[:command]
    terms = params[:text]

    commands_by_user = RunCommand.where user: user, command: command
    puts "#{user_name} has run this command #{commands_by_user.size} times."

    if commands_by_user.size > 0
      last_lenny = commands_by_user.last
      too_recent = last_lenny.created_at + 1.minute > Time.now
      puts "#{user_name} last ran it too recently!" if too_recent
      puts "Should not lenny" if too_recent && !power_user
      return "Wait a bit, will ya?" if too_recent && !power_user
    end

    new_command = RunCommand.new user: user, command: command
    new_command.save

    lenny_count = RunCommand.where("command = '/lenny' AND created_at >= ?", 10.seconds.ago).count
    lennies = case terms
    when /spook/i
      SPOOKED_LENNYS
    else
      LENNYS
    end
    lenny_index = [lenny_count - 1, lennies.count - 1].min
    lenny = lennies[lenny_index]

    if FAKE_RESPONSE
      puts "#{user_name} did a lenny."
      return lenny
    end

    Chat.new(channel).chat_out(lenny)
  end
end

