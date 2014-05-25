#!/usr/bin/env ruby
require "open-uri"
require "pdf-reader"

class Hour
  include Comparable

  attr_reader :hour, :minute, :type

  def initialize(h, m, type = nil)
    @hour = h
    @minute = m
    @type = type
  end

  def self.parse(text)
    _, h, m, t = text.match(/(\d{1,2}):(\d{2})(\w*)/).to_a
    Hour.new(h.to_i, m.to_i, t)
  end

  def to_s
    "%d:%02d#{type}" % [hour, minute]
  end

  def to_minutes
    60*hour + minute
  end

  def <=>(other)
    to_minutes <=> other.to_minutes
  end

  def self.now
    parse Time.now.strftime('%H:%M')
  end
end

class Timetable
  @@types = [:week, :sat, :sun, :hol].freeze


  attr_reader :name

  def initialize(name)
    @name = name
    @timetable = Hash.new {|hash, key| hash[key] = [] }
  end

  def self.types
    @@types
  end

  def add(hour, type = types.first)
    idx = @timetable[type].index {|item| item > hour } || -1
    @timetable[type].insert(idx, hour)
  end



  def self.today_type
    case Time.now.wday
    when 0 then :sun
    when 6 then :sat
    else :week
    end
  end

  def get(type = nil)
    type ||= self.class.today_type
    @timetable[type]
  end
end

class SkBusParser < Timetable
  @@url = "http://www.skbus.com.pl"

  def self.url
    @@url
  end

  def self.parse(path)
    text = PDF::Reader.new( open("#{url}/#{path}") ).page(1).text

    _, from, direction = text.match(/odjazdy z (\w+) .*do (\w+)/i).to_a
    timetable = self.new("Z #{from.capitalize} do #{direction.capitalize}")

    idx = 0
    last = nil

    text.scan(/\d{1,2}:\d{2}S?/).each do |hour|
      h = Hour.parse(hour)
      t = types[idx]
      if !last.nil? and last > h
        idx += 1
        idx %= 4
      end
      t = types[idx]
      timetable.add(h, t)
      last = h
    end

    timetable
  end

  def self.parse_all
    @@timetables ||= open("#{url}/rozklady.html").read.scan(/href="(.*pdf)"/).map(&:first).first(4).map do |path|
      self.parse(path)
    end
  end

end


# puts SkBusParser.parse_all.inspect
