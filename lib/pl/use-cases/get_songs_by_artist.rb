module PL
  class GetSongsByArtist < UseCase
    def run(artist)
      songs_by_artist = PL.db.get_songs_by_artist(artist)
      return success :songs_by_artist => songs_by_artist
    end
  end
end
