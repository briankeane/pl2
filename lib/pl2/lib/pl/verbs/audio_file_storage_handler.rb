
require 'aws-sdk'

module PL
  class AudioFileStorageHandler

    def initialize
      @s3 = AWS::S3.new
    end

    def grab_audio(audio_block)
      case
      when audio_block.is_a?(PL::Song)
        bucket = @s3.buckets[S3['SONGS_BUCKET']]
      when audio_block.is_a?(PL::Commercial)
        bucket = @s3.buckets[S3['COMMERCIALS_BUCKET']]
      when audio_block.is_a?(PL::Commentary)
        bucket = @s3.buckets[S3['COMMENTARIES_BUCKET']]
      end

      s3_song_file = bucket.objects[audio_block.key]
      temp_audio_file = Tempfile.new('temp_audio_file')
      temp_audio_file.binmode
      temp_audio_file.write(s3_song_file.read)

      return temp_audio_file
    end
    
    ###########################################################
    #    store_commentary(attrs) :schedule_id, duration,      #
    #         :audio_file                                     #
    ###########################################################
    #  returns a string with the new_aws_key                  #
    ###########################################################
    def store_commentary(attrs)
      bucket = @s3.buckets[S3['COMMENTARIES_BUCKET']]

      stored_commentaries_keys = bucket.objects.collect(&:key)

      # figure out what the next_key_value will be
      if stored_commentaries_keys.count == 0
        next_key_value = 0
      else     
        next_key_value = stored_commentaries_keys.max_by { |key| key[4..10].to_i }[4..10].to_i
      end
      
      next_key_value += 1


      new_key = ('_com' + ('0' * (7 - next_key_value.to_s.size)) +  next_key_value.to_s + '_' + attrs[:schedule_id].to_s + '_' + '.mp3')

      commentary_file = File.open(attrs[:audio_file])
      commentary_file.binmode
      bucket.objects[new_key].write(:file => commentary_file)
      aws_commentary_object = bucket.objects[new_key]

      attrs[:key] = new_key

      aws_commentary_object.metadata[:pl_duration] = attrs[:duration] if attrs[:duration]
      aws_commentary_object.metadata[:pl_shedule_id] = attrs[:schedule_id] if attrs[:schedule_id]

      return new_key
    end



    #####################################################
    #    store_song(attrs) :title, :artist, :album,     #
    #       :duration, :song_file, :echonest_id         #
    #####################################################
    #  returns a string with the new_aws_key            #
    #####################################################
    def store_song(attrs)
      bucket = @s3.buckets[S3['SONGS_BUCKET']]

      stored_song_keys = bucket.objects.collect(&:key)

      # figure out what the next_key_value will be
      if stored_song_keys.count == 0
        next_key_value = 0
      else     
        next_key_value = stored_song_keys.max_by { |key| key[4..10].to_i }[4..10].to_i
      end
      
      next_key_value += 1


      new_key = ('_pl_' + ('0' * (7 - next_key_value.to_s.size)) +  next_key_value.to_s + '_' + attrs[:artist] + '_' + attrs[:title] + '.mp3')

      song_file = File.open(attrs[:song_file])
      song_file.binmode
      bucket.objects[new_key].write(:file => song_file)
      aws_song_object = bucket.objects[new_key]

      attrs[:key] = new_key

      self.update_stored_song_metadata(attrs)

      return new_key
    end

    def update_stored_song_metadata(attrs)
      bucket = @s3.buckets[S3['SONGS_BUCKET']]

      aws_song_object = bucket.objects[attrs[:key]]
      aws_song_object.metadata[:pl_title] = attrs[:title] if attrs[:title]
      aws_song_object.metadata[:pl_artist] = attrs[:artist] if attrs[:artist]
      aws_song_object.metadata[:pl_album] = attrs[:album] if attrs[:album]
      aws_song_object.metadata[:pl_duration] = attrs[:duration] if attrs[:duration]
      aws_song_object.metadata[:pl_echonest_id] = attrs[:echonest_id] if attrs[:echonest_id]

    end

    def get_stored_song_metadata(key)
      
      bucket = @s3.buckets[S3['SONGS_BUCKET']]

      if !bucket.objects[key].exists?
        return nil
      end

      aws_song_object = bucket.objects[key]

      metadata = {}

      metadata[:title] = aws_song_object.metadata[:pl_title]
      metadata[:artist] = aws_song_object.metadata[:pl_artist]
      metadata[:album] = aws_song_object.metadata[:pl_album]
      metadata[:duration] = aws_song_object.metadata[:pl_duration].to_i
      metadata[:echonest_id] = aws_song_object.metadata[:pl_echonest_id]
      metadata
    end
    
    def get_all_songs
      all_s3_objects = @s3.buckets[S3['SONGS_BUCKET']].objects
      songs = []
      
      # for display
      total = all_s3_objects.count
      puts

      all_s3_objects.each_with_index do |s3_object, i|
        print "\rSong #{i + 1} of #{total}"
        song = Song.new({ artist: s3_object.metadata[:pl_artist],
                          title: s3_object.metadata[:pl_title],
                          album: s3_object.metadata[:pl_album],
                          duration: s3_object.metadata[:pl_duration].to_i,
                          echonest_id: s3_object.metadata[:pl_echonest_id],
                          key: s3_object.key })
        songs << song
      end
      return songs
    end

    def get_unprocessed_song_audio(key)
      @s3 = AWS::S3.new

      bucket = @s3.buckets[S3['UNPROCESSED_SONGS']]

      s3_song_file = bucket.objects[key]

      temp_audio_file = Tempfile.new('temp_audio_file')
      temp_audio_file.binmode
      temp_audio_file.write(s3_song_file.read)
      return temp_audio_file
    end

    def delete_unprocessed_song(key)
      s3_song_file = @s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].delete
    end

    def delete_song(key)
      @s3.buckets[S3['SONGS_BUCKET']].objects[key].delete
      return true
    end

  end
end