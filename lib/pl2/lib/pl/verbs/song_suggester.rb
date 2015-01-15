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
    # Takes an  an array of up to 5 artists and returns          #
    # a playlist of suggested songs                              #
    ##############################################################

    def get_suggestions(*artists)
      # if a single string has been passed...
      if artists[0].is_a?(Array)
        artists = artists[0]
      end

      # load the list with songs by the artists
      final_list = []
      artists.each do |artist|
        artist_songs = PL.db.get_songs_by_artist(artist).first(3)
        artist_songs.each { |song| final_list << song }
      end


      list = Echowrap.playlist_static(artist: artists.join(', '), 
                                      type: 'artist-radio',
                                      results: 100, 
                                      limit: true,
                                      bucket: 'id:' + ECHONEST_KEYS['TASTE_PROFILE_ID'])

      list.each do |song|
        final_list << PL.db.get_song_by_echonest_id(song.id) unless (!PL.db.get_song_by_echonest_id(song.id) || final_list.index{ |final_list_song| final_list_song.id == song.id })
      end
      final_list
    end

    def get_suggestions_alt_beta(*artists)
      list = Echowrap.playlist_basic(artist: artists, 
                                      type: 'artist-radio',
                                      results: 100, 
                                      limit: true,
                                      bucket: 'id:' + ECHONEST_KEYS['TASTE_PROFILE_ID'])
      final_list = []
      list.each do |song|
        final_list << PL.db.get_song_by_echonest_id(song.id) unless !PL.db.get_song_by_echonest_id(song.id)
      end
      final_list
    end
  end
end