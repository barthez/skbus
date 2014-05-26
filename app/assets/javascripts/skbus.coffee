class SkBus
  constructor: ->
    @updateTime()
    setInterval (=> @updateTime()), 1000

  currentTime: ->
    date = new Date()
    [@dh ? date.getHours(), @dm ? date.getMinutes()]

  updateTime: ->
    [h, m] = @currentTime()
    # h = "0#{h}" if h < 10
    m = "0#{m}" if m < 10
    element  = $('.current-time span')
    element
      .html( "#{h}<em>:</em>#{m}")
      .toggleClass('colon')


    past = $('.timetable li:not(.past)')
      .filter (idx) ->
        time = $(this).text().split(':')
        _h = parseInt(time[0])
        _m = parseInt(time[1])
        _h < h || (_h == h && _m < m)



    if past.length > 0
      past.addClass('past')
      $('.timetable li:not(.past)')
        .slice(0, 3)
        .removeClass('first-1 first-2 first-3')
        .each (idx, el) ->
          $(el).addClass("first-#{idx+1}")


    $('.timetable').each (idx, el) ->
      if $('li:not(.past)', el).length == 0
        $('li', el)
          .removeClass('past first-1 first-2 first-3')
          .slice(0, 3)
          .each (idx, el) ->
            $(el).addClass("first-#{idx+1}")

      $(el).toggleClass('even-past', $('li.past', el).length % 2 == 0)

window.skbus = new SkBus()

