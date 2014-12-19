require 'aws-sdk'

module PL
  class ProcessSong < UseCase
    def run(key)
      ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new
      song_pool = PL::SongPoolHandler.new
      ac = PL::AudioConverter.new

      temp_song_file = ash.get_unprocessed_song_audio(key)
      extension = File.extname(temp_song_file)

      # get tags
      case
      when (extension == '.mp3') || (extension == '.wav')
        tags = sp.get_id3_tags(temp_song_file)

      when (extension == '.mp4') || (extension == '.m4a') || (extension == '.m4p')
        tags = sp.get_id4_tags(temp_song_file)
      end

      # return failure if file is encrypted
      if tags[:encrypted]
        return failure :file_is_encrypted
      end
      
      # return failure if song exists
      if PL.db.song_exists?({ artist: tags[:artist], title: tags[:title], album: tags[:album] })
        ash.delete_unprocessed_song(key)
        song = PL.db.get_songs_by_title_and_artist({ artist: tags[:artist], title: tags[:title] })[0]
        return failure(:song_already_exists, { tags: tags, key: key, song: song })
      end

      # return failure if tags incomplete
      case 
      when !tags[:title] || tags[:title].strip.size == 0
        return failure(:no_title_in_tags, {tags: tags, key: key })
      when !tags[:artist] || tags[:artist].strip.size == 0
        return failure(:no_artist_in_tags, {tags: tags, key: key })
      end

      #perform conversion if necessary
      case 
      when (extension == '.mp4') || (extension == '.m4a') || (extension == '.m4p')
        temp_song_file = File.open(ac.mp4_to_mp3(temp_song_file.path))
      end

      song = sp.add_song_to_system(temp_song_file)

      if song == false
        echonest_info = sp.get_echonest_info({ artist: tags[:artist],
                                                title: tags[:title] })
        return failure(:no_echonest_match_found, { echonest_info: echonest_info,
                                                         tags: tags,
                                                          key: key })
      else 
        ash.delete_unprocessed_song(key)
        return success song: song
      end
    end
  end
end
