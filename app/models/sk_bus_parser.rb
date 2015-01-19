require "open-uri"
require "pdf-reader"

class SkBusParser < Timetable
  @@url = "http://www.skbus.com.pl"

  def initialize(options = {})
    super
    parse_options!
    parse! unless ready?
  end

  def self.by_id(id)
    all.find{|t| t.redis_key.split(':', 2).last == id }
  end

  def self.parse(path)
      self.new(path: path)
  end

  def self.all
    @@timetables ||= urls.map do |path|
      self.parse(path)
    end
  end

  def self.urls
    _urls = Scheduler.redis.get("#{redis_key_part}:_urls")
    if _urls.nil?
      _urls = open("#{@@url}/rozklady.html").read.scan(/href="(.*pdf)"/).map(&:first).first(4)
      Scheduler.redis.set("#{redis_key_part}:_urls", _urls.to_json)
    else
      _urls = JSON.parse(_urls)
    end
    _urls.reverse
  end

  def self.redis_key_part
    name.sub('Parser', '').underscore
  end

  def self.make_key(url)
    url.sub(%r{[/-]}, '_').sub('.pdf', '')
  end

  private

  def parse_options!
    raise "Missing :path in options" unless options[:path]
    @path = options[:path]
    key_part = self.class.make_key(@path)
    @redis_key = "#{self.class.redis_key_part}:#{key_part}"
    _timetable_json = Scheduler.redis.get("#{@redis_key}:timetable")
    if _timetable_json
      @timetable = JSON.parse(_timetable_json).symbolize_keys
      @timetable.each_value do |table|
        table.map!{|h| Hour.new(h["hour"], h["minute"], h["type"].presence) }
      end
      @timetable.default_proc = proc {|hash, key| hash[key] = [] }
      @name = Scheduler.redis.get("#{@redis_key}:name")
      @ready = true
    end

  end

  def parse!
    text = PDF::Reader.new( open("#{@@url}/#{@path}") ).page(1).text
    from, direction = text.match(/odjazdy z (\w+) .*do (\w+)/i).captures
    @name = "Z #{from.capitalize} do #{direction.capitalize}"

    idx = 0
    last = nil

    text.scan(/\d{1,2}:\d{2}S?/).each do |hour|
      h = Hour.parse(hour)
      t = self.class.types[idx]
      if !last.nil? and last > h
        idx += 1
        idx %= 4
      end
      t = self.class.types[idx]
      add(h, t)
      last = h
    end

    redis_set!
  end

  def redis_set!
    Scheduler.redis.set("#{@redis_key}:name", @name)
    Scheduler.redis.set("#{@redis_key}:timetable", @timetable.to_json)
  end

end


# puts SkBusParser.parse_all.inspect
