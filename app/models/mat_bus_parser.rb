require 'net/http'
require 'pp'

class MatBusParser < Timetable
  extend RedisCache
  @@url = "http://matbus.pl"

  attr_reader :id

  URL_KEY = %r{(?<=d/).*(?=/pubhtml)}
  DAYS_MAP = {
    /PON/ => :week,
    /SB|SOBOTA/ => :sat,
    /ND|NIEDZIELA/ => :sun,
    /ŚWIĘTA/ => :hol
  }

  def self.urls
    html = Nokogiri::HTML open("#{@@url}/przewozy_regularne").read
    html.css('#gpx_content a').map do |link|
      description = link.text
      info =  description.slice!(/\(.*\)/)
      connection = description.strip.split(/\s*-\s*/)
      url = get_timeline_url( URI.join(@@url, link['href']).to_s)
      each_route(connection).map do |route|
        [route, info, url]
      end if url
    end.compact.flatten(1)
  end
  class_redis_cache :urls

  def self.redis_key
    "mat_bus"
  end

  def self.each_route(connection)
    if connection.first == connection.last
      n = connection.size/2 + 1
      [connection.first(n), connection.last(n)]
    else
      [connection, connection.reverse]
    end
  end

  def self.all
    urls.map do |route, info, url|
      new(route: route, info: info, url: url)
    end
  end

  def self.by_id(id)
    all.detect { |t| t.id == id }
  end

  def initialize(options = {})
    @route = options[:route]
    @info = options[:info]
    @url = options[:url].sub(/(?<=pubhtml).*$/, '')
    super(name: @route.join(' - '))
    @id = @route.join('-').downcase
    @redis_key = "#{self.class.redis_key}:#{@url[URL_KEY]}"
  end

  def timetable
    @timetable = Timetable::TYPES.map { |type| [type, []] }.to_h

    html = Nokogiri::HTML(open(@url).read)
    rows = html.css('tr').reject { |row| row.text.empty? || row.at_css('td')['colspan']  }
    timetables = rows.map { |row| row.css('td').map(&:text) }.transpose
    timetables = timetables.first(timetables.size/2)
    hours = timetables.shift.map(&:to_i)
    timetables.each do |day|
      types = nil
      day.each_with_index do |minute, idx|
        if idx == 0
          values = DAYS_MAP.select { |k, _| k =~ minute }.values
          types = values.any? ? values : [:week]
        end
        minute.scan(/\d{1,2}[A-Z]{0,2}/) do |m, t|
          h = Hour.new(hours[idx], m.to_i, t)
          types.each do |type|
            add(h, type)
          end
        end
      end
    end
    @timetable.each_value(&:sort!)
  end
  redis_cache :timetable

  private

  def self.get_timeline_url(url)
    content = open(url).read
    iframe = Nokogiri::HTML(content).at_css('iframe')
    iframe['src'] if iframe
  end
end
