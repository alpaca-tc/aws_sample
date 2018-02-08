Rails.application.routes.draw do
  root to: 'root#index'

  resource :google
end
