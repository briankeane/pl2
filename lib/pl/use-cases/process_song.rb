require 'aws-sdk'
require 'mp3info'

module PL
  class ProcessSong < UseCase
    def run(key)

      ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new
      song_pool = PL::SongPoolHandler.new

      temp_song_file = ash.get_unprocessed_song_audio(key)
      id3_tags = sp.get_id3_tags(temp_song_file)

      # return failure if id3_tags incomplete
      case 
      when !id3_tags[:title] || id3_tags[:title].strip.size == 0
        return failure(:no_title_in_id3_tags, { id3_tags: id3_tags, key: key })
      when !id3_tags[:artist] || id3_tags[:artist].strip.size == 0
        return failure(:no_artist_in_id3_tags, { id3_tags: id3_tags, key: key })
      end

      if PL.db.song_exists?({ artist: id3_tags[:artist], title: id3_tags[:title], album: id3_tags[:album] })
        ash.delete_unprocessed_song(key)
        return failure(:song_already_exists, { id3_tags: id3_tags, key: key })
      end

      song = sp.add_song_to_system(temp_song_file)

      if song == false
        echonest_info = sp.get_echonest_info({ artist: id3_tags[:artist],
                                                title: id3_tags[:title] })
        return failure(:no_echonest_match_found, { echonest_info: echonest_info,
                                                          id3_tags: id3_tags,
                                                          key: key } )
      else 
        ash.delete_unprocessed_song(key)
        return success song: song
      end
    end
  end
end
