require 'echowrap'

module PL
  class SongSuggester
    
    def initialize
      Echowrap.configure do |config|
        config.api_key = ECHONEST_KEYS['API_KEY']
        config.consumer_key = ECHONEST_KEYS['CONSUMER_KEY']
        config.shared_secret = ECHONEST_KEYS['SHARED_SECRET']
      end
    end
    
    ##############################################################
    # Takes an artist or an array of up to 5 artists and returns #
    # a playlist of suggested songs                              #
    ##############################################################

    def get_suggestions(*artists)
      list = Echowrap.playlist_basic(artist: artists, results: 100, limited_interactivity: true)
      list.sort_by! { |x| [x.artist_name, x.title] }.map! { |x| { artist: x.artist_name, 
                                                                title: x.title,
                                                                echonest_id: x.id,
                                                                echonest_artist_id: x.artist_id } }
                                                                binding.pry
    end

  end
end