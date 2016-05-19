# coding: utf-8

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
    str =~ /\b#{name_regex}$/
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

class Kelvin < Unit
    @name_regex = "K(elvin)?"
    @formats = [/(-?\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Ounce < Unit
  @name_regex = "([Oo]z|[Oo]unce(s)?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Liter < Unit
  @name_regex = "([Ll](iters?)?)" #fuck British spelling
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Gallon < Unit
  @name_regex = "([Gg]al(lons?)?)"
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Quart < Unit
  @name_regex = "(([Qq]uart)s? | ([Qq]t)s?)" 
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Pint < Unit
  @name_regex = "(([Pp]int)s? | ([Pp]t)s?)" 
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Cup < Unit
  @name_regex = "([Cc]ups? | [Cc]opas?)" #Spanish is allowable
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Lightyear < Unit
  @name_regex = "([Ll]ightyears? | [Ll][Yy]s?)" 
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

class Parsec < Unit
  @name_regex = "([Pp]arsecs? | [Pp]cs?)" #FuckGeorgeLucas Parsec is a unit of distance 
  @formats = [/(\d+(\.\d+)?)\s*#{name_regex}$/]
end

UNITS = [Foot, Meter, Centimeter, Mile, Kilometer, Inch, Pound, Kilogram, Fahrenheit, Celsius, Kelvin, Ounce, Liter, Gallon, Quart, Pint, Cup, Lightyear, Parsec]
TABLE = {
  Foot => {Meter => 0.3048,
           Inch => 12,
           Kilometer => 0.0003048,
           Centimeter => 30.48,
           Mile => 0.000189393939},
  Meter => {Foot => 0.3048,
            Inch => 39.3701,
            Centimeter => 100,
            Kilometer => 0.001,
            Mile => 0.000621371},
  Centimeter => {Foot => 0.0328084,
                 Meter => 0.01,
                 Inch => 0.393701},
  Mile => {Kilometer => 1.60934,
           Foot => 5280,
           Meter => 1609.34},
  Kilometer => {Mile => 0.621371,
                Foot => 3280.84,
                Meter => 1000.0},
  Inch => {Foot => 0.083333,
           Centimeter => 2.54,
           Meter => 0.0254},
  Parsec => {LightYear => 0.306601}, #will add support for miles/kilometers once mutoid adds support for scientific notation
  Lightyear => {Parsec => 3.26156},
  Pound => {Kilogram => 0.453592,
		Ounce => 16},
  Kilogram => {Pound => 2.20462,
	       Ounce => 35.274},
  Ounce => {Pound => 0.0625,
	    Kilogram => 0.0283495},
  Fahrenheit => { Celsius => Proc.new { |f| (f - 32) * 5.0 / 9.0 },
                 Kelvin => Proc.new { |f| (f + 459.67) * 5.0 / 9.0 }},
  Celsius => { Fahrenheit => Proc.new { |c| (c * 9.0 / 5.0) + 32 },
               Kelvin => Proc.new { |c| (c + 273.15) } },
  Kelvin => { Celsius => Proc.new { |k| (k - 273.15) },
              Fahrenheit => Proc.new { |k| (k * 9.0 / 5.0) - 459.67 } },
  Liter => {Gallon => 0.264172,
	    Quart => 1.05669,
	    Pint => 2.11338,
	    Cup => 4.22675},
  Gallon => {Liter => 3.78541,
	     Quart => 4,
	     Pint => 8,
	     Cup => 16},
  Quart => {Liter => 0.946353,
	    Gallon => 0.25,
	    Pint => 2,
	    Cup => 4},			
  Pint => {Liter => 0.473176,
  	   Gallon => 0.125,
	   Quart => 0.5,
	   Cup => 2},		
  Cup => {Liter => 0.236588,
	  Gallon => 0.0624,
	  Quart => 0.25,
	  Pint => 0.5}
}
