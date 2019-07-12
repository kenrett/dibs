Rails.application.routes.draw do
  root to: 'messages#index'

  post '/message' => 'messages#index'
end
