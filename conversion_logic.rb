# coding: utf-8
# -*- coding: utf-8 -*-

require './chat'
require './user_privs'
require './unit_mixin'

class ConversionLogic
  def self.convert(from, from_unit, to_unit)
    f = from_unit.new(from)
    rules = TABLE[from_unit]
    if (!rules)
      raise "Can't find a conversion rule for #{from_unit}!"
    end
    conversion = rules[to_unit]
    raise "Don't know how to convert from #{from_unit} to #{to_unit}!" if !conversion
    value = if conversion.is_a? Proc
              conversion.call(f.value)
            else
              f.value * conversion
            end
    to_unit.new(value).format
  end
  
  def self.process(params)
    channel = params[:channel_id]
    channel_name = params[:channel_name]
    user_name = params[:user_name]
    user_id = params[:user_id]
    power_user, admin_user = UserPrivilege.user_privs(user_id)
    command = params[:command]
    terms = params[:text]

    new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
    new_command.save

    begin
      result = do_logic(terms)
    rescue e
      return e.message
    end

    Chat.new(channel).chat_out "_#{user_name} converted #{terms}_ => *#{result}*"
  end

  def self.do_logic(terms)
    from, to = /(.+) to (.+)/.match(terms)[1..2]
    raise "Could not understand request." if (from == nil || to == nil)

    from_unit = UNITS.select { |u| u.identify? from }[0]
    raise "Unable to recognize FROM unit" if !from_unit

    to_unit = UNITS.select { |u| u.to_identify? to }[0]
    raise "Unable to recognize TO unit" if !to_unit
    
    convert(from, from_unit, to_unit)
  end
end

class Unit
  include ClassLevelInheritableAttributes
  attr_accessor :value
  inheritable_attributes :formats, :name_regex
  @formats = []
  @name_regex = ""
  
  def initialize(val)
    @value = if (val.is_a? Float)
               val
             else
               parse(val)
             end
  end

  def self.identify?(val)
    formats.any? { |f| val =~ f }
  end

  def self.to_identify?(str)
    str =~ /\b#{name_regex}/
  end

  def format
    "%.3f" % value
  end

  private
  
  def parse(val)
    self.class.formats.select { |f| val =~ f }.first.match(val)[1].to_f
  end
end

class Foot < Unit
  @name_regex = "f(ee|oo)?t"
  @formats = [/(\d+)'\s*(\d+(\.\d+)?)"/, /(\d+(\.\d+)?)\s*#{name_regex}/]

  def parse(val)
    if (match_data = self.class.formats[0].match(val))
      return match_data[1].to_f + match_data[2].to_f / 12.0
    elsif (match_data = self.class.formats[1].match(val))
      return match_data[1].to_f
    end
  end

  def format
    return super if value < 1 || value > 10
    fraction = value.modulo(1)
    feet = (value - fraction).round(0)
    inches = (fraction * 12).round(0)
    "#{feet}'#{inches}\""
  end
end

class Meter < Unit
  @name_regex = "m(eters?)?"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Centimeter < Unit
  @name_regex = "(cm|centimeters?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Mile < Unit
  @name_regex = "(mi(les)?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Kilometer < Unit
  @name_regex = "(km|kilometers?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Inch < Unit
  @name_regex = "(in|\"|inch(es)?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Pound < Unit
  @name_regex = "(lbs?|#|pounds)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Kilogram < Unit
  @name_regex = "(kg|kilograms?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Fahrenheit < Unit
  @name_regex = "([Dd]egrees )?[Ff](ahrenheit)?"
  @formats = [/(-?\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Celsius < Unit
  @name_regex = "([Dd]egrees )?[Cc](elsius|entigrade)?"
  @formats = [/(-?\d+(\.\d+)?)\s*#{name_regex}$/]
end

UNITS = [Foot, Meter, Centimeter, Mile, Kilometer, Inch, Pound, Kilogram, Fahrenheit, Celsius]
TABLE = {
  Foot => {Meter => 0.3048,
           Inch => 0.0833333,
           Kilometer => 3280.84,
           Centimeter => 30.48},
  Meter => {Foot => 0.3048,
            Inch => 0.0254,
            Centimeter => 0.01,
            Kilometer => 0.001,
            Mile => 1609.34},
  Centimeter => {Foot => 0.0328084,
                 Meter => 100,
                 Inch => 2.54},
  Mile => {Kilometer => 0.621371,
           Foot => 5280,
           Meter => 1609.34},
  Kilometer => {Mile => 1.60934,
                Foot => 0.0003048,
                Meter => 1000.0},
  Inch => {Foot => 12.0,
           Centimeter => 0.393701,
           Meter => 39.3701},
  Pound => {Kilogram => 0.453592},
  Kilogram => {Pound => 2.20462},
  Fahrenheit => {Celsius => Proc.new { |f| (f - 32) * 5.0 / 9.0 } },
  Celsius => {Fahrenheit => Proc.new { |c| (c * 9.0 / 5.0) + 32 } }
}
