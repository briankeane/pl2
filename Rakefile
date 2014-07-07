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

  task :load_songs => [:load_app] do
    PL.db.clear_everything

    puts "Seeding database"
    # configure s3
    AWS.config ({
                    :access_key_id     => S3_KEYS['ACCESS_KEY_ID'],
                    :secret_access_key =>  S3_KEYS['SECRET_KEY']
                    })

    s3 = AWS::S3.new

    bucket = 'playolasongs'
    stored_songs = s3.buckets['playolasongs'].objects
    stored_song_keys = stored_songs.collect(&:key)

    # separate out un-processed songs
    unprocessed_song_keys = []
    stored_song_keys.delete_if do |key|
      if !key.match(/^_pl_/)
        unprocessed_song_keys << key
        true
      else
        false
      end
    end

    # find the max key_value so far and increment it
    if stored_song_keys.count == 0
      next_key_value = 0
    else     
      next_key_value = stored_song_keys.max_by { |key| key[4..10].to_i }[4..10].to_i
    end
    
    next_key_value += 1

    # process the unprocessed songs
    unprocessed_song_keys.each_with_index do |key, i|
      print "\rProcessing song #{i + 1} of #{unprocessed_song_keys.count}"

      s3_song_file = stored_songs[key]

      # download the song
      temp_song_file = Tempfile.new("temp_song_file")

      temp_song_file.open()
      temp_song_file.write(s3_song_file.read)

      # get the id3 tags
      mp3 = ''
      Mp3Info.open(temp_song_file) do |song_tags|
        mp3 = song_tags
      end

      artist = mp3.tag.artist || ''
      title = mp3.tag.title || ''
      album = mp3.tag.album || ''
      duration = (mp3.length * 1000).to_i

      #create the song object and add it to the db
      song = PL.db.create_song({ title: title,
                                artist: artist,
                                album: album,
                                duration: duration
                          })

      new_key = ('_pl_' + ('0' * (7 - next_key_value.to_s.size)) +  next_key_value.to_s + '_' + song.artist + '_' + song.title + '.' + '.mp3')
      next_key_value += 1

      s3.buckets['playolasongs'].objects[new_key].write(:file => temp_song_file)

      # delete old copy
      s3.buckets['playolasongs'].objects[key].delete

      # store metadata
      aws_song_object = s3.buckets['playolasongs'].objects[new_key]
      aws_song_object.metadata[:pl_title] = title
      aws_song_object.metadata[:pl_artist] = artist
      aws_song_object.metadata[:pl_album] = album
      aws_song_object.metadata[:pl_duration] = duration

      song = PL.db.update_song({ id: song.id, key: new_key })
    end

    puts "Unprocessed Songs Finished..."

    #store the processed songs in the db
    stored_song_keys.each_with_index do |key, i|
      print "\rAdding song #{i + 1} of #{stored_song_keys.count}"

      s3_song_file = stored_songs[key]
      
      #create a song hash
      song = {}

      # IF the song is missing any of the metadata
      if (!s3_song_file.metadata[:pl_duration] ||
                      !s3_song_file.metadata[:pl_artist] ||
                      !s3_song_file.metadata[:pl_album] ||
                      !s3_song_file.metadata[:pl_duration])
        temp_song_file = Tempfile.new("temp_song_file")

        temp_song_file.open()
        temp_song_file.write(s3_song_file.read)

        # get the id3 tags
        mp3 = ''
        
        Mp3Info.open(temp_song_file) do |song_tags|
          mp3 = song_tags
        end

        # store the metadata on amazon s3
        s3_song_file.metadata[:pl_artist] = mp3.tag.artist
        s3_song_file.metadata[:pl_title] = mp3.tag.title
        s3_song_file.metadata[:pl_album] = mp3.tag.album
        s3_song_file.metadata[:pl_duration] = (mp3.length * 1000).to_i
      end

      # finish creating the song object
      song[:artist] = s3_song_file.metadata[:pl_artist]
      song[:title] = s3_song_file.metadata[:pl_title]
      song[:album] = s3_song_file.metadata[:pl_album]
      song[:duration] = s3_song_file.metadata[:pl_duration]
      song[:key] = key

      # write to the db
      stored_song = PL.db.create_song(song)
    end
  end

  task :clear_users do
  end
end