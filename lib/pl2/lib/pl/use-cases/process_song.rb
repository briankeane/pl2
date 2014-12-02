require 'aws-sdk'
require 'mp3info'

module PL
  class ProcessSong < UseCase
    def run(attrs)
     ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new
      song_pool = PL::SongPoolHandler.new

      temp_song_file = ash.get_unprocessed_song_audio(attrs[:key])
      extension = File.extname(attrs[:filename])

      # get tags
      case
      when (extension == '.mp3') || (extension == '.wav')
        info = sp.get_id3_tags(temp_song_file)

      when (extension == '.mp4') || (extension == '.m4a')
        info = MP4Info.file(temp_song_file)


        
        temp_song_file
      end

        # return failure if file is encrypted
        if info[:encrypted]
          return failure :file_is_encrypted
        end
        
        # return failure if song exists
        if PL.db.song_exists?({ artist: tags[:artist], title: tags[:title], album: tags[:album] })
          ash.delete_unprocessed_song(key)
          return failure(:song_already_exists, { tags: tags, key: attrs[:key] })
        end

        # return failure if tags incomplete
        case 
        when tags[:title] ||tags[:title].strip.size == 0
          return failure(:no_title_intags, {tags: tags, key: attrs[:key] })
        when tags[:artist] ||tags[:artist].strip.size == 0
          return failure(:no_artist_intags, {tags: tags, key: attrs[:key] })
        end

      song = sp.add_song_to_system(temp_song_file)

      if song == false
        echonest_info = sp.get_echonest_info({ artist: tags[:artist],
                                                title: tags[:title] })
        return failure(:no_echonest_match_found, { echonest_info: echonest_info,
                                                         tags: tags,
                                                          key: attrs[:key] })
      else 
        ash.delete_unprocessed_song(attrs[:key])
        return success song: song
      end
    end
  end
end
