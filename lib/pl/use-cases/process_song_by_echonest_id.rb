require 'aws-sdk'
require 'mp3info'

module PL
  class ProcessSongByEchonestId < UseCase
    def run(attrs)
      ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new


      echonest_data = sp.get_echonest_info_by_echonest_id(attrs[:echonest_id])

      if !echonest_data
        return failure(:echonest_id_not_found)
      elsif PL.db.song_exists?(echonest_data)
        return failure :song_already_exists
      end

      temp_song_file = ash.get_unprocessed_song_audio(attrs[:key])
      
      id3_tags = sp.get_id3_tags(temp_song_file)

      # correct id3_tags if necessary
      tags_to_fix = {}
      tags_to_fix[:artist] = echonest_data[:artist] unless (id3_tags[:artist] == echonest_data[:artist])
      tags_to_fix[:title] = echonest_data[:title] unless (id3_tags[:title] == echonest_data[:title])


      if tags_to_fix.size > 0
        tags_to_fix[:song_file] = temp_song_file
        sp.write_id3_tags(tags_to_fix)
      end


      # process the file
      song = sp.add_song_to_system(temp_song_file)

      ash.delete_unprocessed_song(attrs[:key])

      temp_song_file.unlink

      return success :song => song
      
    end
  end
end