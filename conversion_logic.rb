# coding: utf-8
# -*- coding: utf-8 -*-

require './chat'
require './unit_mixin'
require 'bigdecimal'
require 'set'

class ConversionLogic
  def self.convert(from, from_unit, to_unit)
    f = from_unit.new(from)

    raise "Don't know how to convert from #{from_unit} to #{to_unit}!" if !compatible?(from_unit, to_unit)

    table = table(from_unit, to_unit)
    middle_conversion = table.select { |u, _| u == from_unit }.first
    final_conversion = table.select { |u, _| u == to_unit }.first
    middle_unit = table[0][0]

    mid_value = if middle_conversion[1].is_a? Proc
                  middle_conversion[2].call(f.value)
                else
                  f.value / middle_conversion[1]
                end

    final_value = if final_conversion[1].is_a? Proc
                    final_conversion[1].call(mid_value)
                  else
                    mid_value * final_conversion[1]
                  end
    to_unit.new(final_value).format
  end
  
  def self.process(params)
    channel = params[:channel_id]
    channel_name = params[:channel_name]
    user_name = params[:user_name]
    user_id = params[:user_id]
    command = params[:command]
    terms = params[:text]

    new_command = RunCommand.new user_id: user_id, user_name: user_name, command: command
    new_command.save

    begin
      result = do_logic(terms)
    rescue Exception => e
      return e.message
    end

    Chat.new(channel).chat_out "_#{user_name} converted #{terms}_ => *#{result}*"
  end

  def self.do_logic(terms)
    terms = terms.tr("’”", "'\"")
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
  FLOAT_REGEX = '(\d*\.)?\d+'
  @formats = []
  @name_regex = ""
  
  def initialize(val)
    @value = if val.is_a? Float
               BigDecimal.new(val, 10)
             elsif val.is_a? BigDecimal
               val
             else
               parse(val)
             end
  end

  def self.identify?(val)
    formats.any? { |f| val =~ f }
  end

  def self.to_identify?(str)
    str =~ /\b#{name_regex}$/
  end

  def format
    "%0.5g" % value
  end

  private
  
  def parse(val)
    BigDecimal.new(self.class.formats.select { |f| val =~ f }.first.match(val)[1])
  end
end

class Foot < Unit
  @name_regex = "f(ee|oo)?t"
  @formats = [/(\d+)'\s*(#{FLOAT_REGEX})"/, /(#{FLOAT_REGEX})\s*#{name_regex}/]

  def parse(val)
    if match_data = self.class.formats[0].match(val)
      return BigDecimal.new(match_data[1]) + BigDecimal.new(match_data[2]) / 12.0
    elsif match_data = self.class.formats[1].match(val)
      return BigDecimal.new match_data[1]
    end
  end

  def format
    return super if value < 1 || value > 10
    fraction = value.modulo(1)
    feet = (value - fraction).round(0)
    inches = (fraction * 12)
    inch_fraction = inches.modulo(1)
    inches = inches.round(0)
    inch_fraction = Rational(inch_fraction - inch_fraction.modulo(Rational('1/16')))
    if (inch_fraction > 0)
      "#{feet}' #{inches} #{inch_fraction}\""
    else
      "#{feet}'#{inches}\""
    end
  end
end

class Meter < Unit
  @name_regex = "m(eters?)?"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Centimeter < Unit
  @name_regex = "(cm|centimeters?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Mile < Unit
  @name_regex = "(mi(les)?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Kilometer < Unit
  @name_regex = "(km|kilometers?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Inch < Unit
  @name_regex = "(in|\"|inch(es)?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Pound < Unit
  @name_regex = "(lbs?|#|pounds)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Kilogram < Unit
  @name_regex = "(kg|kilograms?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Fahrenheit < Unit
  @name_regex = "([Dd]egrees )?[Ff](ahrenheit)?"
  @formats = [/(-?#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Celsius < Unit
  @name_regex = "([Dd]egrees )?[Cc](elsius|entigrade)?"
  @formats = [/(-?#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Kelvin < Unit
    @name_regex = "K(elvin)?"
    @formats = [/(-?#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Ounce < Unit
  @name_regex = "([Oo]z|[Oo]unce(s)?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Liter < Unit
  @name_regex = "([Ll](iters?)?)" #fuck British spelling
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Gallon < Unit
  @name_regex = "([Gg]al(lons?)?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Quart < Unit
  @name_regex = "(([Qq]uart)s?|([Qq]t)s?)" 
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Pint < Unit
  @name_regex = "(([Pp]int)s?|([Pp]t)s?)" 
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Cup < Unit
  @name_regex = "([Cc]ups?|[Cc]opas?)" #Spanish is allowable
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Lightyear < Unit
  @name_regex = "([Ll]ight ?years?|[Ll][Yy]s?)"
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Parsec < Unit
  @name_regex = "([Pp]arsecs?|[Pp]cs?)" #FuckGeorgeLucas Parsec is a unit of distance 
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

class Yard < Unit
  @name_regex = "([Yy]ards?|[Yy]ds?)" #Imperial4lyfe
  @formats = [/(#{FLOAT_REGEX})\s*#{name_regex}$/]
end

UNITS = [Foot, Meter, Centimeter, Mile, Kilometer, Inch, Pound, Kilogram, Fahrenheit, Celsius, Kelvin, Ounce, Liter, Gallon, Quart, Pint, Cup, Lightyear, Parsec, Yard]

# First unit is the "master unit" by which all units are calculated to and from.
# Value in the second part of the tuple is what you have to multiply by to get
# from the "master unit" to the unit in question.
LENGTH_UNITS = [[Meter, 1.0],
                [Foot, 3.28084],
                [Centimeter, 100],
                [Mile, 0.000621371],
                [Kilometer, 0.001],
                [Inch, 39.3701],
                [Lightyear, 1.057e-16],
                [Parsec, 3.2408e-17],
                [Yard, 1.09361]]
WEIGHT_UNITS = [[Kilogram, 1.0],
                [Pound, 2.20462],
                [Ounce, 35.274]]
VOLUME_UNITS = [[Liter, 1.0],
                [Ounce, 33.814],
                [Gallon, 0.264172],
                [Quart, 1.05669],
                [Pint, 2.11338],
                [Cup, 16]]
TEMPERATURE_UNITS = [[Celsius, 1.0],
                     [Fahrenheit, Proc.new { |c| (c * 9.0 / 5.0) + 32 }, Proc.new { |f| (f - 32) * 5.0 / 9.0 }],
                     [Kelvin, Proc.new { |c| (c + 273.15) },  Proc.new { |k| (k - 273.15) } ]]

def compatible?(from, to)
  !table(from, to).nil?
end

def table(from, to)
  [LENGTH_UNITS, WEIGHT_UNITS, VOLUME_UNITS, TEMPERATURE_UNITS].select { |list|
    list.map(&:first).to_set & [from, to] == [from, to].to_set
  }.first
end
