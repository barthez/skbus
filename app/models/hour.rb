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
    parse Time.zone.now.strftime('%H:%M')
  end
end