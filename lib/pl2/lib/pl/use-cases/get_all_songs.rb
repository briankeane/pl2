module PL
  class GetAllSongs < UseCase
    def run(blank=nil)
      all_songs = PL.db.get_all_songs
      return success :all_songs => all_songs
    end
  end
end
