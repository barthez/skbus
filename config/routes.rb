Rails.application.routes.draw do

  scope controller: :application do
    root action: :index
  end

end
