Rails.application.routes.draw do

  scope controller: :application do
  	get :polymer
    root action: :index
  end

end
