class SkBus
  constructor: ->
    setInterval (=> @updateTime()), 1000

  updateTime: ->
    date = new Date()
    h = date.getHours()
    m = date.getMinutes()
    # h = "0#{h}" if h < 10
    m = "0#{m}" if m < 10
    element  = $('.current-time span')
    element
      .html( "#{h}<em>:</em>#{m}")
      .toggleClass('colon')

    $('.timetable li:not(.past)')
      .filter (idx) ->
        time = $(this).text().split(':')
        _h = parseInt(time[0])
        _m = parseInt(time[1])
        _h < h || (_h == h && _m < m)
      .addClass('past')

    if $('.timetable li:not(.past)').length == 0
      $('.timetable li').removeClass('past')



window.skbus = new SkBus()

