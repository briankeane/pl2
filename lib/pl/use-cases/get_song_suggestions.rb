module PL
  class GetSongSuggestions < UseCase
    def run(artists)
      ss = SongSuggester.new
      song_suggestions = ss.get_suggestions(artists)
      return success :song_suggestions => song_suggestions
    end
  end
end
