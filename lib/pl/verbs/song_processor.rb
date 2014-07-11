require 'mp3info'
require 'echowrap'

module PL
  class SongProcessor
    def initialize
      Echowrap.configure do |config|
        config.api_key = ECHONEST_KEYS['API_KEY']
        config.consumer_key = ECHONEST_KEYS['CONSUMER_KEY']
        config.shared_secret = ECHONEST_KEYS['SHARED_SECRET']
      end
    end

    def add_song_to_system(song_file)
      # Read the id3 tags
      tags = self.get_id3_tags(song_file)
      

      # IF there were no ID3 tags
        # Get Fingerprint
        # Check EchoNest for Match
      # ELSE Get proper title and artist from echonest
      # Store on S3
      # Add to Echonest
      # Add to DB
    end

    ######################################
    #    get_id3_tags(song_file)         #
    ######################################
    #  returns a hash with id3 tags      #
    ######################################

    def get_id3_tags(song_file)
      mp3 = ''
      Mp3Info.open(song_file) do |song_tags|
        mp3 = song_tags
      end

      tags = mp3.tag
      
      # convert the keys to symbols
      tags.keys.each do |key|
        tags[(key.to_sym rescue key) || key] = tags.delete(key)
      end

      tags[:duration] = (mp3.length * 1000).to_i
      return tags
    end

    def get_echo_nest_info(attrs) # takes title and artist
      echo_tags = Echowrap.song_search(combined: attrs[:artist] + ' ' + attrs[:title], results: 1)[0].attrs
      binding.pry
      echo_tags[:artist] = echo_tags.delete(:artist_name)
      return echo_tags
    end

  end
end