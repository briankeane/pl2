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

    def get_suggestions(artists)
      list = Echowrap.playlist_static(artist: artists, 
                                      type: 'catalog',
                                      results: 100, 
                                      limited_interactivity: true,
                                      seed_catalog: ECHONEST_KEYS['TASTE_PROFILE_ID'])
      list.sort_by! { |x| [x.artist_name, x.title] }.map! { |song| PL.db.get_song_by_echonest_id(song.id) }
      list                                       
    end

  
  end
end