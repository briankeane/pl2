module PL
  class GetEchonestId < UseCase
    def run(attrs)
      sp = SongProcessor.new
      echo_tags = sp.get_echonest_info(attrs)
      
      if (echo_tags[:artist_match_rating] < 0.8) || (echo_tags[:title_match_rating] < 0.8)
        return failure(:no_echonest_id_found)
      end

      return success echonest_id: echo_tags[:echonest_id], title: echo_tags[:title], artist: echo_tags[:artist]
    end
  end
end