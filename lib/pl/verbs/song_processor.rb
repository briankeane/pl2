require 'mp3info'
require 'echowrap'
require 'fuzzystringmatch'
require 'aws-sdk'

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
      

      # Convert it to mp3 if it's a wav file
      if song_file.path.match(/\.wav$/)
        audio_converter = PL::AudioConverter.new       
        song_file = File.open(audio_converter.wav_to_mp3(wav_file.path))
      end

      # from id3 tags
      tags = self.get_id3_tags(song_file)

      echo_tags = self.get_echo_nest_info({ title: tags[:title], artist: tags[:artist] })

      # IF these are a not close match, exit with failure
      jarow = FuzzyStringMatch::JaroWinkler.create( :native )
      if (jarow.getDistance(tags[:artist].downcase, echo_tags[:artist].downcase) < 0.75) || 
                    (jarow.getDistance(tags[:title].downcase, echo_tags[:title].downcase) < 0.75)
  
        return false
      end

      # Store the song
      handler = PL::AudioFileStorageHandler.new
      key = handler.store_song({ song_file: song_file,
                        artist: echo_tags[:artist],
                        album: echo_tags[:album],
                        title: echo_tags[:title],
                        duration: tags[:duration]
                        })


      # Add to Echonest
      data = '[{ "item": {
                  "item_id":"#{key}",
                  "song_id":"#{echo_tags[:song_id]}",
                  "item_keyvalues": {
                    "pl_artist": "#{echo_tags[:artist]}",
                    "pl_key" : "#{echo_tags[:key]}",
                    "pl_album": "#{echo_tags[:album]}",
                    "pl_title": "#{echo_tags[:duration]}",
                    "pl_duration": "#{tags[:duration]}"
                  }
                }}]'

      Echowrap.taste_profile_update(:id => ECHONEST_KEYS['TASTE_PROFILE_ID'], :data => data )




      # Add to DB
      song = PL.db.create_song({ artist: tags[:artist],
                          album: tags[:album],
                          title: tags[:title],
                          duration: tags[:duration],
                          key: key })

      return song
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
      echo_tags = Echowrap.song_search(combined: (attrs[:artist] || '') + ' ' + (attrs[:title] || ''), results: 1)[0].attrs

      # rename some attrs for consistency
      echo_tags[:artist] = echo_tags.delete(:artist_name)
      echo_tags[:echonest_id] = echo_tags.delete(:id)

      return echo_tags
    end

  end
end