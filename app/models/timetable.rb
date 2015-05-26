class Timetable
  TYPES = @@types = [:week, :sat, :sun, :hol].freeze

  attr_reader :name, :options, :redis_key, :timetable

  def initialize(options = {})
    @name = options[:name]
    @options = options
  end

  def self.types
    @@types
  end

  def self.all
    []
  end

  def add(hour, type = types.first)
    @timetable[type].push(hour)
  end

  def global_id
    [self.class.name.sub(/Parser$/, '').underscore, id].compact.join('-')
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
    timetable[type]
  end
end
