module PL
  class GetSongsByTitle < UseCase
    def run(title)
      songs_by_title = PL.db.get_songs_by_title(title)
      return success :songs_by_title => songs_by_title
    end
  end
end
