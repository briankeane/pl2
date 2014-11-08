module PL
  class UpdateSong < UseCase
    def run(attrs)
      song = PL.db.get_song(attrs[:id])

      if !song
        return failure(:song_not_found)
      else
        song = PL.db.update_song(attrs)
        return success :song => song
      end
    end
  end
end