module PL
  class GetSong < UseCase
    def run(id)
      song = PL.db.get_song(id)
      
      if !song
        return failure(:song_not_found)
      else
        return success :song => song
      end
    end
  end
end