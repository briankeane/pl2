Rails.application.routes.draw do
  
  get 'users/delete'

  get 'users/show'

  # welcome_controller paths
  root :to => 'welcome#home'
  match '/about',     to: 'welcome#about',  via: 'get'

  # station_controller paths
  match 'dj_booth',                     to: 'stations#dj_booth',               via: 'get'
  match 'playlist_editor',              to: 'stations#playlist_editor',        via: 'get'
  match 'station/update_order'          =>  'stations#update_order',           via: 'put' 
  match 'station/add_to_rotation',      to: 'stations#add_to_rotation',        via: 'post'
  match 'station/delete_from_rotation', to: 'stations#delete_from_rotation',   via: 'delete'
  match 'station/new',                  to: 'stations#new',                    via: 'get'
  match 'station/create',               to: 'stations#create',                 via: 'post'
  match 'session/destroy',              to: 'sessions#destroy',                via: 'get'
  match 'users/update',                 to: 'users#update',                    via: 'post'
  match 'upload',                       to: 'upload#upload',                   via: 'get'

  # sessions_controller paths
  get '/auth/twitter/callback', to: 'sessions#create_with_twitter'


end
