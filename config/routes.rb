Rails.application.routes.draw do
  get 'visitors/index'

  resources :events
  resources :blogs
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/redirect', to: 'google#redirect', as: 'redirect'
	get '/callback', to: 'google#callback', as: 'callback'
	get '/calendars', to: 'google#calendars', as: 'calendars'
	get '/event/:calendar_id', to: 'google#events', calendar_id: /[^\/]+/
	post '/event/:calendar_id', to: 'google#new_event', calendar_id: /[^\/]+/

  root to: 'visitors#index'
end
