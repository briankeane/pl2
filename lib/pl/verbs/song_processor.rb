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

      accurate_tags = {}

      # create mp3 and wav versions
      audio_converter = PL::AudioConverter.new

      # IF it's a wav file
      if song_file.path.match(/\.wav$/)
        wav_file = song_file
        mp3_file = File.open(audio_converter.wav_to_mp3(wav_file.path))
      else
        mp3_file = song_file
        wav_file = File.open(audio_converter.mp3_to_wav(mp3_file).path)
      end

      # from id3 tags
      tags = self.get_id3_tags(mp3_file)
      
      # from 
      fingerprint_tags = {}
      binding.pry
      fingerprint_results = `../echoprint-codegen spec/test_files/stepladder.mp3 10 30`
      fingerprint_json = JSON.parse(fingerprint_results)
      fingerprint_tags[:artist] = fingerprint_json[0]["metadata"]["artist"] || ''
      fingerprint_tags[:album] = fingerprint_json[0]["metadata"]["release"] || ''
      fingerprint_tags[:duration] = fingerprint_json[0]["metadata"]["duration"].to_i * 1000  || 0
      fingerprint_tags[:title] = fingerprint_json[0]["metadata"]["title"] || ''
      # IF these are a not close match
      jarow = FuzzyStringMatch::JaroWinkler.create( :native )
      if (jarow.getDistance(tags.artist, fingerprint_tags[:artist]) < 0.75) || 
                    (jarow.getDistance(tags.title, fingerprint_tags[:title]) < 0.75)
          # IF the fingerprint is not empty
          if fingerprint_tags[:artist] != ''

            # look up echonest tags using fingerprints
            echonest_tags = self.get_echo_nest_info({ artist: fingerprint_tags[:artist],
                                                      title: fingerprint_tags[:title] })
          else  # otherwise use the id3 tags
            echonest_tags = self.get_echo_nest_info({ artist: tags.artist,
                                                      title: tags.title })
          end

      else
        echonest_tags = fingerprint_tags
      end

      # Store the song
      afh = PL::AudioFileHandler.new
      key = afh.store_song({ song_file: mp3_song_file,
                        artist: accurate_tags[:artist],
                        album: accurate_tags[:album],
                        title: accurate_tags[:title],
                        duration: accurate_tags[:duration]
                        })


      # Add to Echonest

      # Add to DB
      PL.db.create_song({ artist: accurate_tags[:artist],
                          album: accurate_tags[:album],
                          title: accurate_tags[:title],
                          duration: accurate_tags[:duration],
                          key: key })
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