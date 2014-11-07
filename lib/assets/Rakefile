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

task :sandbox => [:load_app] do
  binding.pry
end

namespace :db do
  task :migrate do
    puts "Migrating database"
    # [code to migrate database would go here]
  end

  task :clear_users => [:load_app, :clear_schedules, :clear_stations] do
    puts 'Clearing Users'
    PL.db.destroy_all_users
  end

  task :clear_stations => [:load_app, :clear_schedules] do
    puts 'Clearing Stations...'
    PL.db.destroy_all_stations
  end

  task :clear_schedules => [:load_app] do
    puts 'Clearing Schedules...'
    PL.db.destroy_all_schedules
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
    song_pool.clear_all_songs
    song_pool.add_songs(all_stored_songs.dup)
    

    puts "Adding Songs to db"
    all_stored_songs.each_with_index do |song, i|
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

  task :update_stored_songs_info => [:load_app] do
    # create the handlers
    ash = PL::AudioFileStorageHandler.new
    sp = PL::SongProcessor.new
    song_pool = PL::SongPoolHandler.new

    puts "Getting all currently stored info..."
    all_songs = ash.get_all_songs
    puts
    puts "           artist:                                             title:"
    puts "----------------------------------------------------------------------"
    all_songs.each_with_index do |song, i|

      # grab the file
      temp_song_file = ash.grab_audio(song)
      
      # get it's tags
      tags = sp.get_id3_tags(temp_song_file)

      # grab the songpool info
      echonest_info = sp.get_echonest_info({ title: tags[:title], artist: tags[:artist] })

      # decide on final values
      finalized_info = {}
      finalized_info[:key] = song.key
      finalized_info[:duration] = tags[:duration]
      finalized_info[:album] = tags[:album]


      # use the id3 tags if no suitable match found
      if (echonest_info[:artist_match_rating] < 0.8) || (echonest_info[:title_match_rating] < 0.8)
        finalized_info[:artist] = tags[:artist]
        finalized_info[:title] = tags[:title]
        finalized_info[:echonest_id] == 'SET_TO_NIL'
      else
        finalized_info[:echonest_id] = echonest_info[:echonest_id]
      end

      ash.update_stored_song_metadata(finalized_info)
      
      tags[:artist] ||= ''
      tags[:title] ||= ''
      echonest_info[:artist] ||= ''
      echonest_info[:title] ||= ''

      puts "     id3: " + tags[:artist] + (' ' * (50 - tags[:artist].size)) + tags[:title]
      puts "echonest: " + echonest_info[:artist] + (' ' * (50 - echonest_info[:artist].size)) + echonest_info[:title]

      puts "   match: " + echonest_info[:artist_match_rating].round(3).to_s + (' ' * (50 - echonest_info[:artist_match_rating].round(3).to_s.size)) + echonest_info[:title_match_rating].round(3).to_s
      
      if finalized_info[:echonest_id] == nil
        puts "ECHONEST_ID NOT UPDATED"
      end
      
      puts

    end

  end
end