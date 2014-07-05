Rails.application.routes.draw do

  root :to => 'welcome#home'
  match '/about',     to: 'welcome#about',  via: 'get'

end
