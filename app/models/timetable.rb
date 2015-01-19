class Timetable
  @@types = [:week, :sat, :sun, :hol].freeze

  attr_reader :name, :options, :redis_key

  def initialize(options = {})
    @name = options[:name]
    @options = options
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

  def ready?
    @ready
  end

  def get(type = nil)
    type ||= self.class.today_type
    @timetable[type]
  end
end