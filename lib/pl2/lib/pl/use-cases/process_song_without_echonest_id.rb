require 'aws-sdk'
require 'mp3info'

module PL
  class ProcessSongWithoutEchonestId < UseCase
    def run(attrs)
      ash = PL::AudioFileStorageHandler.new
      sp = PL::SongProcessor.new

      temp_song_file = ash.get_unprocessed_song_audio(attrs[:key])
      extension = File.extname(temp_song_file)

      # get tags
      case
      when (extension == '.mp3') || (extension == '.wav')
        tags = sp.get_id3_tags(temp_song_file)

      when (extension == '.mp4') || (extension == '.m4a') || (extension == '.m4p')
        tags = sp.get_id4_tags(temp_song_file)
      end

      tags_to_fix = {}

      # correct tags if necessary
      if (attrs[:artist] && (attrs[:artist] != tags.artist))
        tags_to_fix[:artist] = attrs[:artist]
        tags[:artist] = attrs[:artist]
      end

      if (attrs[:title] && (attrs[:title] != tags.title))
        tags_to_fix[:title] = attrs[:title]
        tags[:title] = attrs[:title]
      end

      if (attrs[:album] && (attrs[:album] != tags.album))
        tags_to_fix[:album] = attrs[:album]
        tags[:album] = attrs[:album]
      end

      if tags_to_fix.size > 0
        tags_to_fix[:song_file] = temp_song_file
        sp.write_tags(tags_to_fix)
      end

      if PL.db.song_exists?(tags)
        return failure :song_already_exists
      end

      #perform conversion if necessary
      case 
      when (extension == '.mp4') || (extension == '.m4a') || (extension == '.m4p')
        temp_song_file = File.open(ac.mp4_to_mp3(temp_song_file.path))
      end

      # process the file
      song = sp.add_song_to_system_without_echonest_id(temp_song_file)

      ash.delete_unprocessed_song(attrs[:key])

      temp_song_file.unlink

      return success :song => song
      
    end
  end
end
