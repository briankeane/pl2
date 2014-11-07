require 'aws-sdk'
require 'mp3info'

module PL
  class ProcessSongWithoutEchonestId < UseCase
    def run(attrs)
      ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new

      temp_song_file = ash.get_unprocessed_song_audio(attrs[:key])
      
      id3_tags = sp.get_id3_tags(temp_song_file)

      tags_to_fix = {}

      # correct id3_tags if necessary
      if (attrs[:artist] && (attrs[:artist] != id3_tags.artist))
        tags_to_fix[:artist] = attrs[:artist]
        id3_tags[:artist] = attrs[:artist]
      end

      if (attrs[:title] && (attrs[:title] != id3_tags.title))
        tags_to_fix[:title] = attrs[:title]
        id3_tags[:title] = attrs[:title]
      end

      if (attrs[:album] && (attrs[:album] != id3_tags.album))
        tags_to_fix[:album] = attrs[:album]
        id3_tags[:album] = attrs[:album]
      end

      if tags_to_fix.size > 0
        tags_to_fix[:song_file] = temp_song_file
        sp.write_id3_tags(tags_to_fix)
      end

      if PL.db.song_exists?(id3_tags)
        return failure :song_already_exists
      end

      # process the file
      song = sp.add_song_to_system_without_echonest_id(temp_song_file)

      ash.delete_unprocessed_song(attrs[:key])

      temp_song_file.unlink

      return success :song => song
      
    end
  end
end
