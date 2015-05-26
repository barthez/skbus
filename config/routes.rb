Rails.application.routes.draw do

  scope controller: :application do
  	get '/:timetable', action: :polymer
    root action: :polymer
  end

end
