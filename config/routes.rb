Rails.application.routes.draw do
  root to: 'messages#index'

  get '/provision' => 'provisions#index'
  get '/auth' => 'auths#index'
  post '/message' => 'messages#index'
end
