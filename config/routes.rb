Rails.application.routes.draw do
  
  get 'schedules/add_spin'

  get 'schedules/remove_spin'

  get 'users/delete'

  get 'users/show'

  # welcome_controller paths
  root :to => 'welcome#home'
  match '/about',     to: 'welcome#about',  via: 'get'

  # station_controller paths
  match 'dj_booth',                                 to: 'stations#dj_booth',                         via: 'get'
  match 'playlist_editor',                          to: 'stations#playlist_editor',                  via: 'get'
  match 'station/update_order'                      =>  'stations#update_order',                     via: 'put' 
  match 'station/add_to_rotation',                  to: 'stations#add_to_rotation',                  via: 'post'
  match 'station/delete_from_rotation',             to: 'stations#delete_from_rotation',             via: 'delete'
  match 'station/new',                              to: 'stations#new',                              via: 'get'
  match 'station/song_manager',                     to: 'stations#song_manager',                     via: 'get'
  match 'station/create',                           to: 'stations#create',                           via: 'post'
  match 'session/destroy',                          to: 'sessions#destroy',                          via: 'get'
  match 'users/update',                             to: 'users#update',                              via: 'post'
  match 'uploads/new',                              to: 'uploads#new',                               via: 'get'
  match 'upload/process_song',                      to: 'uploads#process_song',                      via: 'post'
  match 'upload/process_song_without_echonest_id',  to: 'uploads#process_song_without_echonest_id',  via: 'post'
  match 'upload/get_song_match_possibilities',      to: 'uploads#get_song_match_possibilities',      via: 'post'       
  match 'upload/delete_unprocessed_song',           to: 'uploads#delete_unprocessed_song',           via: 'post'
  match 'upload/process_song_by_echonest_id',       to: 'uploads#process_song_by_echonest_id',       via: 'post'
  match 'upload/get_echonest_id',                   to: 'uploads#get_echonest_id',                   via: 'post'
  match '/stations/playlist/create_spin_frequency', to: 'stations#create_spin_frequency',            via: 'post'
  match '/stations/playlist/update_spin_frequency', to: 'stations#update_spin_frequency',            via: 'post'
  match '/stations/playlist/delete_spin_frequency', to: 'stations#delete_spin_frequency',            via: 'delete'
  match '/schedules/move_spin',                     to: 'schedules#move_spin',                       via: 'post'
  match '/schedules/insert_song',                   to: 'schedules#insert_song',                     via: 'post'
  match '/schedules/process_commentary',            to: 'schedules#process_commentary',              via: 'post'
  match '/listens/index',                           to: 'listens#index',                             via: 'get'
  match '/schedules/get_spin_by_current_position',  to: 'schedules#get_spin_by_current_position',    via: 'get'
  match '/schedules/remove_spin',                   to: 'schedules#remove_spin',                     via: 'delete'
  match '/listens/:id',                             to: 'listens#show',                              via: 'get'
  # sessions_controller paths
  get '/auth/twitter/callback', to: 'sessions#create_with_twitter'


end