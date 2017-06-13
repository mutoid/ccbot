# coding: utf-8
# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'sinatra'
require 'sinatra/activerecord'
require './environments'
require './chat'
require './user_privileges'
require './megamoji'
require './pin'
require './lenny_logic'
require './gifme_logic'
require './conversion_logic'
require './megamoji_logic'
require './pin_logic'
require './user'
require './run_command'

class BotLogic < Sinatra::Base
  before do
    @user = User.find_or_create(params[:user_name], params[:user_id])
  end

  get('/') do
    puts "Processing get / request"
    "I'm up."
  end

  post('/quote') do
    puts "Quoting a user..."
    result = PinLogic.new(params).quote
    break result if result
  end

  post('/convert') do
    puts "Doing a unit conversion..."
    puts "Params: ", params
    result = ConversionLogic.process(params)
    break result if result
  end

  post('/gifme') do
    puts "Getting a random gif from gifme.io..."
    puts "Params: ", params

    result = GifmeLogic.process(params)
    break result if result
  end

  post('/megamoji') do
    puts "Constructing a large rectangular emoji..."
    puts "Params: ", params

    result = MegamojiLogic.process(params)

    break result if result
  end

  post('/archivepins') do
    puts "Deleting all pins and saving them in the db!"

    PinLogic.new(params).remove_all_pins
  end

  post('/roll') do
    begin
      puts "Rolling dice"
      n, m, modifier = params[:text].scan(/\d+/)
      accum = [] 
      n = n.to_i
      m = m.to_i
      if (n <= 0 or m <= 0) or (n > 20 and m > 20) or (n > 100 or m > 100) # Non-numeric chars = 0, this limits size
        break "Invalid roll"
      end
      n.to_i.times {
        accum.append(Random.new.rand(m.to_i) + 1)
      }


      channel = params[:channel_id]
      output = "#{params[:user_name]} rolled (#{params[:text]}) - " + (accum.to_s) + " -  #{accum.sum + modifier}"
      puts "roll done"
      Chat.new(channel).chat_out(output)
    rescue
        puts "problem with roll"
        break "Problem with roll"
    end
  end

  post('/ruby') do
    puts "Evaluating Ruby code from the web, WCGW?"
    puts "Params: ", params

    channel = params[:channel_id]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = UserPrivilege.user_privs(@user)
    break "You don't have permission to do this." if !admin_user

    @current_channel = channel
    @current_user_name = user_name
    
    code = params[:text]

    # #YOLO dawg
    result = nil
    begin
      Timeout.timeout(30) do
        result = eval(code)
      end
    rescue SyntaxError => se
      break "There was a syntax error in #{code} #{se.message}"
    rescue StandardError => e
      break "There was an error: #{e.message}"
    end
    output =  "_#{user_name} ran some Ruby code:_\n```#{code}```\n"
    output << "``` => #{result}```" if !result.nil?

    Chat.new(channel).chat_out(output)
  end

  post('/lenny') do
    puts "Processing /lenny command"
    puts "Params: ", params

    user_message = LennyLogic.process(params)
    break user_message if user_message
  end

  run! if app_file == $0
end

def count_to_lenny(count, report_width, max_bar)
  lenny_full = '( ͡° ͜ʖ ͡°)'
  lenny_2_3 = '( ͡° ͜ʖ'
  lenny_1_3 = '( ͡°'
  lennies = (report_width * count / max_bar)
  whole_lennies = lennies.to_i
  remainder = lennies - whole_lennies
  lenny_full * lennies + (remainder > 0.66 ? lenny_2_3 : (remainder > 0.33 ? lenny_1_3 : ""))
end

def lenny_graph(report_width=12.0)
  report_width = report_width.to_f
  total_count = RunCommand.count
  name_length = RunCommand.pluck(:user).uniq.map(&:length).max + 1
  report = RunCommand.joins(:user).where(command: '/lenny').map { |x| [x.user.user_id, x.user.user_name] }.group_by(&:first).map { |k, v| [v.first.last, v.count] }
  max_bar = report.max_by { |name, count| count }.last
  name_format_string = "%-#{name_length}.#{name_length}s"
  lenny_scale = (max_bar / report_width).round(2)
  report.sort_by(&:last).reverse!.map { |name, count|
    "#{name_format_string % (name[0] + '*' + name[2..-1])}|#{count_to_lenny(count, report_width, max_bar)}"
  }.unshift("THE LENNY GRAPH: ( ͡° ͜ʖ ͡°) = #{lenny_scale} runs of the /lenny command" + "\n").join("\n")
end

def ascii_to_fullwidth s
  wide_map = Hash[(0x21..0x7F).map { |x| [x, x + 0xFEE0] }]
  wide_map[0x20] = 0x3000 # space
  wide_map[0x22] = 0x309B # quote
  wide_map[0x2C] = 0x3001 # comma
  wide_map[0x2D] = 0x30FC # minus
  wide_map[0x2E] = 0x3002 # period
  wide_map[0x3C] = 0x3008 # LT
  wide_map[0x3E] = 0x3009 # GT
  wide_map[0x3F] = 0xFF1F # question mark
  wide_map[0x60] = 0x2018 # grave accent

  s.each_char.to_a.map { |c| wide_map[c.ord] || c.ord }.pack('U*')
end

def echo s
  Chat.new(@current_channel).chat_out s
end

def set_channel_topic topic
  Chat.new(@current_channel).topic topic
end

def cross_word s
  a = ascii_to_fullwidth(s.upcase).each_char.to_a
  "\n" + (a[1..-1].unshift(a.join(" "))).join("\n")
end

def square_word(s, fullwidth = true)
  s = s.upcase
  s = ascii_to_fullwidth(s) if fullwidth
  a = s.each_char.to_a
  "\n" + Array.new(a.length) { |i| a.rotate(i).join(" ") }.join("\n")
end

def all_users(filter = {})
  @all_users ||= {}

  if filter.count == 0
    return @all_users['all'] ||= query_result_to_user_list(RunCommand.joins(:user).all)
  end

  condition_sql = ' 1 = 1 '
  params = []

  if filter[:months_ago]
    condition_sql << " AND created_at > ? "
    params << filter[:months_ago].months.ago
  end

  if filter[:command]
    condition_sql << " AND command LIKE ? "
    params << "%#{filter[:command]}%"
  end

  @all_users["#{condition_sql} #{params}"] ||= query_result_to_user_list(RunCommand.where(condition_sql, *params))
end

def query_result_to_user_list(result)
  result.to_a.map { |c| c.user }.uniq
end

def crown_ruotd
  set_channel_topic("Congratulations to @#{random_username(true)}, today's #random user of the day!")
end

def random_username(purged = false)
  if purged
    all_users months_ago: 3
  else
    all_users
  end.sample.user_name
end

def random_user
  "Randomly-selected user who has run /lenny is: #{random_username}"
end

def emoji_word word
  word.gsub /(\w)/, ':\1\1:'
end
