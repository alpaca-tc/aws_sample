Rails.application.routes.draw do
  root to: 'root#index'

  resource :google
  resource :database
  resource :redis
end
