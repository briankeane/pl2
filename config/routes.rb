Dir["#{File.dirname(__FILE__)}/../app/api/API/V1/*.rb"].each { |f| load(f) }
require_relative '../app/api/API/V1/auth.rb'
require_relative '../app/api/API/V1/songs.rb'
require_relative '../app/api/API/V1/users.rb'
require_relative '../app/api/API/V1/root.rb'


require_relative '../app/api/API/root.rb'

Rails.application.routes.draw do
  # mount the api
  mount API::Root => "/"
  
  get 'stations/add_spin'

  get 'stations/remove_spin'

  get 'users/delete'

  get 'users/show'

  # welcome_controller paths
  root :to => 'welcome#home'
  match '/about',     to: 'welcome#about',  via: 'get'

  # station_controller paths
  match 'dj_booth',                                     to: 'stations#dj_booth',                            via: 'get'
  match 'playlist_editor',                              to: 'stations#playlist_editor',                     via: 'get'
  match 'station/update_order'                          =>  'stations#update_order',                        via: 'put' 
  match 'station/add_to_rotation',                      to: 'stations#add_to_rotation',                     via: 'post'
  match 'station/delete_from_rotation',                 to: 'stations#delete_from_rotation',                via: 'delete'
  match 'station/new',                                  to: 'stations#new',                                 via: 'get'
  match 'station/song_manager',                         to: 'stations#song_manager',                        via: 'get'
  match 'station/create',                               to: 'stations#create',                              via: 'post'
  match 'session/destroy',                              to: 'sessions#destroy',                             via: 'get'
  match 'sessions/create',                              to: 'sessions#create_with_twitter',                 via: 'get'
  match 'users/update',                                 to: 'users#update',                                 via: 'post'
  match 'users/report_listener',                        to: 'users#report_listener',                        via: 'put'
  match 'users/create_preset',                          to: 'users#create_preset',                          via: 'post'
  match 'users/delete_preset',                          to: 'users#delete_preset',                          via: 'delete'
  match 'uploads/new',                                  to: 'uploads#new',                                  via: 'get'
  match 'upload/process_song',                          to: 'uploads#process_song',                         via: 'post'
  match 'upload/process_song_without_echonest_id',      to: 'uploads#process_song_without_echonest_id',     via: 'post'
  match 'upload/get_song_match_possibilities',          to: 'uploads#get_song_match_possibilities',         via: 'post'       
  match 'upload/delete_unprocessed_song',               to: 'uploads#delete_unprocessed_song',              via: 'post'
  match 'upload/process_song_by_echonest_id',           to: 'uploads#process_song_by_echonest_id',          via: 'post'
  match 'upload/get_echonest_id',                       to: 'uploads#get_echonest_id',                      via: 'post'
  match '/stations/playlist/create_spin_frequency',     to: 'stations#create_spin_frequency',               via: 'post'
  match '/stations/playlist/update_spin_frequency',     to: 'stations#update_spin_frequency',               via: 'post'
  match '/stations/playlist/delete_spin_frequency',     to: 'stations#delete_spin_frequency',               via: 'delete'
  match '/stations/get_commercial_block_for_broadcast', to: 'stations#get_commercial_block_for_broadcast',  via: 'get'
  match '/stations/move_spin',                          to: 'stations#move_spin',                           via: 'post'
  match '/stations/insert_song',                        to: 'stations#insert_song',                         via: 'post'
  match '/stations/process_commentary',                 to: 'stations#process_commentary',                  via: 'post'
  match '/stations/index',                              to: 'stations#index',                               via: 'get'
  match '/stations/get_spin_by_current_position',       to: 'stations#get_spin_by_current_position',        via: 'get'
  match '/stations/remove_spin',                        to: 'stations#remove_spin',                         via: 'delete'
  match '/stations/reset_station',                      to: 'stations#reset_station',                       via: 'put'
  match '/stations/now_playing',                        to: 'stations#get_now_playing',                     via: 'get'
  match '/stations/:id',                                to: 'stations#show',                                via: 'get'

  # sessions_controller paths
  get '/auth/twitter/callback', to: 'sessions#create_with_twitter'
  get 'songs/get_songs_by_keywords',                    to: 'songs#get_songs_by_keywords',                  via: 'get'

end
