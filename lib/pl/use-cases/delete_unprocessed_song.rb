module PL
  class DeleteUnprocessedSong < UseCase
    def run(key)
      handler = PL::AudioFileStorageHandler.new
      handler.delete_unprocessed_song(key)
      return success
    end
  end
end