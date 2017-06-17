# coding: utf-8
# -*- coding: utf-8 -*-

class RollLogic
  def self.split_roll(roll)
    puts "Splitting roll into parts"
    #splits a set of rolls into their component parts which look like [+|-]<num_dice>d<dice_size>[k<num_keep>][(+|-)<modifier>]
    regex = /(?<sign>-|\+|^)(?<num_dice>\d{1,3})?d(?<dice_size>\d{1,3})(?:k(?<keep>\d{1,3}))?(?<modifier>(?:[+-])\d{1,3})?(?=\+|-|$)/
    #splits rolls into corresponding MatchData
    rolls = roll.to_enum(:scan, regex).map { Regexp.last_match }
    return rolls
  end

  def self.parse_roll(roll)
    puts "parsing single roll"
    # Filling in potentially missing info, changing the format for "sign"
    full_roll = Hash[roll.names.zip(roll.captures)]
    if full_roll["sign"] == "" or full_roll["sign"] == "+"
      full_roll["sign"] = 1
    else
      full_roll["sign"] = -1
    end

    if !full_roll["num_dice"]
      full_roll["num_dice"] = 1
    end

    if !full_roll["keep"]
      full_roll["keep"] = full_roll["num_dice"]
    end

    if !full_roll["modifier"]
      full_roll["modifier"] = 0
    end

    full_roll.update(full_roll) { |k, v| v.to_i}
    return full_roll
  end


  def self.sum_rolls(rolls_data)
    puts "summing rolls"
    accum = []
    modifier_sum = 0
    if rolls_data.length > 5
      puts "too many rolls"
      return "Too many rolls"
    end

    r = catch(:invalid) {
      rolls_data.each { |roll|
        temp_accum = []
        roll_parsed = RollLogic.parse_roll(roll)
        modifier_sum += roll_parsed["modifier"]

        if ((roll_parsed["num_dice"] <= 0 or roll_parsed["dice_size"]<= 0) or 
            (roll_parsed["num_dice"] > 20 and roll_parsed["dice_size"]> 20) or 
            (roll_parsed["num_dice"] > 100 or roll_parsed["dice_size"]> 100)) # this limits size
          throw :invalid, "Invalid roll"
        end

        roll_parsed["num_dice"].times {
          rand_roll = rand(1..roll_parsed["dice_size"])
          temp_accum << rand_roll
        }
        temp_accum = temp_accum.sort.reverse.take(roll_parsed["keep"]).map { |i| roll_parsed["sign"] * i}
        accum.concat(temp_accum)

      }
    }

    if r == "Invalid roll"
      puts "Invalid roll"
      return r, nil, nil # error, accum, modifier_sum
    end
    puts "roll summed"
    return nil, accum, modifier_sum
  end

  def self.roll_test(text)
    rolls = RollLogic.split_roll(text.gsub( /\s/, ''))
    error, accum, modifier_sum = RollLogic.sum_rolls(rolls)
    if error
      return error
    end
    outstring = "#{text} - #{accum} - #{accum.sum + modifier_sum}"
    puts "roll done"
    return error, outstring

  end

  def self.roll(params)
    begin
      rolls = RollLogic.split_roll(params[:text])
      error, accum, modifier_sum = RollLogic.sum_rolls(rolls)

      if error 
        return error
      end
      
      outstring = "#{params[:user_name]} rolled (#{params[:text]}) - #{accum} -  #{accum.sum + modifier_sum}"
      puts "roll done"
      return error, outstring
    
    rescue StandardError => e
      puts "problem with roll"
      return "Problem with roll - #{e.message}"
    end
  end

end