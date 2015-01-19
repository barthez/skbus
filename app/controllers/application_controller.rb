class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    @timetables = SkBusParser.all

    respond_to :html
  end

  def polymer
    @factory = TimetableFactory.new
    @selected = @factory.by_id(params[:timetable]) || @factory.first

  	render layout: false
  end
end
