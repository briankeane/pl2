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

      # get id3 tags
      tags = self.get_id3_tags(song_file)

      # get closest echonest tags
      echo_tags = self.get_echonest_info({ title: tags[:title], artist: tags[:artist] })

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
                                  duration: tags[:duration],
                                  echo_tags: echo_tags[:echonest_id]
                                  })

      # Add to DB
      song = PL.db.create_song({ artist: tags[:artist],
                                album: tags[:album],
                                title: tags[:title],
                                duration: tags[:duration],
                                key: key,
                                echonest_id: echo_tags[:echonest_id] 
                                })

      # Add to Echonest
      song_pool = SongPoolHandler.new
      song_pool.add_songs(song)

      return song
    end

    def add_song_to_system_without_echonest_id(song_file)
      # Convert it to mp3 if it's a wav file
      if song_file.path.match(/\.wav$/)
        audio_converter = PL::AudioConverter.new       
        song_file = File.open(audio_converter.wav_to_mp3(wav_file.path))
      end

      # get id3 tags
      tags = self.get_id3_tags(song_file)

       # Store the song
      handler = PL::AudioFileStorageHandler.new
      key = handler.store_song({ song_file: song_file,
                                  artist: tags[:artist],
                                  album: tags[:album],
                                  title: tags[:title],
                                  duration: tags[:duration]
                                  })

      # Add to DB
      song = PL.db.create_song({ artist: tags[:artist],
                                album: tags[:album],
                                title: tags[:title],
                                duration: tags[:duration],
                                key: key
                                })
      song
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

    def write_id3_tags(attrs)

      Mp3Info.open(attrs[:song_file].path) do |mp3|
         mp3.tag.title = attrs[:title] unless !attrs[:title]
         mp3.tag.artist = attrs[:artist] unless !attrs[:artist]
         mp3.tag.album = attrs[:album] unless !attrs[:album]
      end 

      return true
    end


    def get_echonest_info(attrs) # takes title and artist

      
      song_list = Echowrap.song_search({ combined: { 
                                            artist: (attrs[:artist] ||= ''), 
                                            title: (attrs[:title] ||= '')
                                          }, 
                                          results: 10 
                                        })
      echo_tags = song_list[0].attrs


      # if it's not a close match, find the closest
      jarow = FuzzyStringMatch::JaroWinkler.create( :native )
      artist_match = jarow.getDistance(attrs[:artist].downcase, echo_tags[:artist_name].downcase)
      title_match = jarow.getDistance(attrs[:title].downcase, echo_tags[:title].downcase)
      if (artist_match < 0.9) || (title_match < 0.9)
        
        closest_match_index = 0
        closest_match_rating = 0
        
        # find the next closest match
        song_list.each_with_index do |tags, i|
          artist_match = jarow.getDistance(attrs[:artist].downcase, tags.artist_name.downcase)
          title_match = jarow.getDistance(attrs[:title].downcase, tags.title.downcase)
          
          match_rating = artist_match + title_match

          if match_rating > closest_match_rating
            closest_title_match = title_match
            closest_artist_match = artist_match
            closest_match_rating = match_rating
            closest_match_index = i
          end
        end

        echo_tags = song_list[closest_match_index].attrs
      end

      # rename some attrs for consistency
      echo_tags[:artist] = (echo_tags.delete(:artist_name) || '')
      echo_tags[:echonest_id] = (echo_tags.delete(:id) || '')
      echo_tags[:artist_match_rating] = jarow.getDistance(attrs[:artist].downcase, echo_tags[:artist].downcase)
      echo_tags[:title_match_rating] = jarow.getDistance(attrs[:title].downcase, echo_tags[:title].downcase)

      return echo_tags
    end

    def get_echonest_info_by_echonest_id(echonest_id)
      begin
        song_profile = Echowrap.song_profile({ :id => echonest_id })
      
      rescue Echowrap::Error::BadRequest
        return nil
      end

      echo_tags = song_profile.attrs
      
      # rename for consistency
      echo_tags[:artist] = (echo_tags.delete(:artist_name) || '')
      echo_tags[:echonest_id] = (echo_tags.delete(:id) || '')
      echo_tags
    end

    def get_song_match_possibilities(attrs)
      song_list = Echowrap.song_search({ combined: { 
                                              artist: (attrs[:artist] ||= ''), 
                                              title: (attrs[:title] ||= '')
                                            }, 
                                            results: 10 
                                          })

      song_list.map! { |song| { artist: song.artist_name,
                                title: song.title,
                                echonest_id: song.id } }

      song_list
    end
  end
end