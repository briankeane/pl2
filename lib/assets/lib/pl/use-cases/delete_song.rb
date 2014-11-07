module PL
  class DeleteSong < UseCase
    def run(id)
      song = PL.db.get_song(id)

      if !song
        return failure :song_not_found
      end

      deleted_song = PL.db.delete_song(id)
      return success :deleted_song => deleted_song
    end
  end
end