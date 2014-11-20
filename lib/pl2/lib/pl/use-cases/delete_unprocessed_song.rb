module PL
  class DeleteUnprocessedSong < UseCase
    def run(key)
      handler = PL::AudioFileStorageHandler.new
      if handler.unprocessed_song_exists?(key)
        handler.delete_unprocessed_song(key)
        return success
      else
        return failure :unprocessed_song_not_found
      end
    end
  end
end