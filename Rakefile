require 'active_record_tasks'

ActiveRecordTasks.configure do |config|
  # These are all the default values
  config.db_dir = 'db'
  config.db_config_path = 'db/config.yml'
  config.env = ENV['RAILS_ENV'] || 'test'
end

# Run this AFTER you've configured
ActiveRecordTasks.load_tasks

task :load_app do
  puts "Loading application"
  # [code to require and set up your application would go here]
  ENV['RAILS_ENV'] ||= 'test'
  require_relative './lib/pl.rb'
  require 'securerandom'
  require 'active_record'
  require 'mp3info'
  require 'aws-sdk'
end

namespace :db do
  task :migrate do
    puts "Migrating database"
    # [code to migrate database would go here]
  end

  task :clear_users => [:load_app] do
    PL.db.destroy_all_users
  end

  task :load_db_via_echonest => [:load_app] do
    PL.db.clear_everything

    song_pool = PL::SongPoolHandler.new
    all_songs = song_pool.all_songs

    
    puts "Adding songs from echonest...."
    all_songs.each_with_index do |song, i|
      print "\rAdding song #{i + 1} of #{all_songs.count}" 
            PL.db.create_song({ title: song.title,
                          artist: song.artist,
                          album: song.album,
                          key: song.key,
                          duration: song.duration,
                          echonest_id: song.echonest_id })
    end

  end

  task :load_db_via_storage => [:load_app] do
    PL.db.clear_everything

    song_pool = PL::SongPoolHandler.new
    song_pool.clear_all_songs

    puts "getting stored songs..."
    @storage = PL::AudioFileStorageHandler.new
    all_stored_songs = @storage.get_all_songs


    puts "Adding Songs to song pool"
    all_stored_songs.each_slice(999) do |songs_chunk|
      song_pool.add_songs(songs_chunk)
    end

    all_songs = song_pool.all_songs

    puts "Adding Songs to db"
    all_songs.each_with_index do |song, i|
      print "\rProcessing song #{i + 1} of #{all_stored_songs.count}"

      song.instance_variables
      PL.db.create_song({ title: song.title,
                          artist: song.artist,
                          album: song.album,
                          key: song.key,
                          duration: song.duration,
                          echonest_id: song.echonest_id })
    end
  end

  task :clear_users do
  end
end