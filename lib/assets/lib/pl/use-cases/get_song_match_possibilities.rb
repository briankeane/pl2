module PL
  class GetSongMatchPossibilities < UseCase
    def run(attrs)
      sp = PL::SongProcessor.new
      songlist = sp.get_song_match_possibilities(attrs)
      return success songlist: songlist
    end
  end
end