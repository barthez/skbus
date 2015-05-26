require "open-uri"
require "pdf-reader"

class SkBusParser < Timetable
  extend RedisCache
  URL = "http://www.skbus.com.pl"

  def initialize(options = {})
    super
    @url = options[:url]
    @redis_key = "#{self.class.redis_key}:#{name.downcase.gsub(/\W+/, '_')}"
  end

  def self.by_id(id)
    all.find{|t| t.id == id }
  end

  def self.all
    urls.map do |name, url|
      self.new(name: name, url: url)
    end
  end

  def self.urls
    html = Nokogiri::HTML(open("#{URL}/rozklady.html").read)
    html.css('a[href$=pdf]').take(4).map do |a|
      link = a['href']
      info = a.ancestors('p').first.at_css('b').text
      [info.each_line.to_a[1].strip, URI.join(URL, link).to_s]
    end
  end
  class_redis_cache :urls

  def self.redis_key
    name.sub('Parser', '').underscore
  end

  def self.make_key(url)
    url.sub(%r{[/-]}, '_').sub('.pdf', '')
  end

  def id
    name.downcase.gsub(/\s+/, '-')
  end

  private

  def parse_options!
  end

  def timetable
    @timetable = Timetable::TYPES.map { |type| [type, []] }.to_h

    text = PDF::Reader.new( open(@url) ).page(1).text

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

    @timetable.each_value(&:sort!)
  end
  redis_cache :timetable
end


# puts SkBusParser.parse_all.inspect
