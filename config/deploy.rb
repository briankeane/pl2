# config valid only for Capistrano 3.1
lock '3.1.0'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :application, 'pl2'
set :repo_url, 'https://github.com/briankeane/pl2.git'

set :branch, ENV['BRANCH'] || "master"

set :deploy_to, '/home/deploy/pl2'

# set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system lib/pl2/secrets}
# set :linked_files, %w{secrets/database.yml config/config.yml}
# set :linked_files, %w{secrets/echonest_config.yml lib/pl2/secrets/echonest_config.yml}
# set :linked_files, %w{secrets/filepicker_config.yml lib/pl2/secrets/filepicker_config.yml}
# set :linked_files, %w{secrets/s3_config.yml lib/pl2/secrets/s3_config.yml}
# set :linked_files, %w{secrets/twitter_config.yml lib/pl2/secrets/twitter_config.yml}


# namespace :config do
#   desc "Symlink application config files."
#   task :symlink do
#     execute :ln "-s {#{shared_path}/secrets/echonest_config.yml,#{release_path}}/lib/pl2/secrets/echonest_config.yml"  
#     execute :ln "-s {#{shared_path}/secrets/filepicker_config.yml,#{release_path}}/lib/pl2/secrets/filepicker_config.yml"  
#     execute :ln "-s {#{shared_path}/secrets/s3_config.yml,#{release_path}}/lib/pl2/secrets/s3_config.yml"  
#     execute :ln "-s {#{shared_path}/secrets/twitter_config.yml,#{release_path}}/lib/pl2/secrets/twitter_config.yml"  
#   end
# end


#before "deploy:assets:precompile", "config:symlink"

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end