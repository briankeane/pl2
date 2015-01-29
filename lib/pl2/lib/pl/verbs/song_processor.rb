require 'mp3info'
require 'mp4info'
require 'taglib'
require 'echowrap'
require 'fuzzystringmatch'
require 'aws-sdk'
require 'net/http'
require 'i18n'


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

      audio_converter = PL::AudioConverter.new
      # Convert it to mp3 if it's a wav file
      if song_file.path.match(/\.wav$/)       
        song_file = File.open(audio_converter.wav_to_mp3(wav_file.path))
        song_file = File.open(audio_converter.trim_silence(song_file.path))
      end

      # get id3 tags
      tags = self.get_id3_tags(song_file)

      # trim silences
      audio_converter.trim_silence(song_file.path)
      
      # get closest echonest tags
      echo_tags = self.get_echonest_info({ title: tags[:title], artist: tags[:artist] })

      # IF these are a not close match, exit with failure
      jarow = FuzzyStringMatch::JaroWinkler.create( :native )
      if (jarow.getDistance(tags[:artist].downcase, echo_tags[:artist].downcase) < 0.75) || 
                    (jarow.getDistance(tags[:title].downcase, echo_tags[:title].downcase) < 0.75)
        return false
      end

      # grab the artwork if it exists
      itunes_info = self.get_itunes_info({ title: tags[:title],
                                          artist: tags[:artist] })
      if !itunes_info
        itunes_info = {}
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
                                echonest_id: echo_tags[:echonest_id],
                                album_artwork_url: itunes_info[:album_artwork_url],
                                itunes_track_view_url: itunes_info[:itunes_track_view_url]
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

    def get_id4_tags(song_file)
      file = TagLib::MP4::File.new(song_file.path)
      tag = file.tag
      tags = {}
      tags[:artist] = tag.artist
      tags[:album] = tag.album
      tags[:title] = tag.title

      # use mp4info for encrypted? and duration
      info = MP4Info.open(song_file)
      tags[:duration] = (info.SECS * 1000) + info.MS
      tags[:artist] = (info.ART || '') unless tags[:artist]
      tags[:album] = (info.ALB || '') unless tags[:album]
      tags[:title] = (info.NAM || '') unless tags[:title]

      if info.ENCRYPTED
        tags[:encrypted] = true
      else
        tags[:encrypted] = false
      end

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
      begin
        song_list = Echowrap.song_search({ combined: { 
                                              artist: (attrs[:artist] ||= ''), 
                                              title: (attrs[:title] ||= '')
                                            }, 
                                            results: 10 
                                          })
      rescue Echowrap::Error
        puts "timeout error... retrying"
        retry
      end

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

      # grab genre tags
      begin
        echo_tags[:genres] = Echowrap.artist_profile({ :name => echo_tags[:artist], 
                                        :bucket => 'genre' 
                                        }).attrs[:genres].map { |x| x[:name] } # returns an array of strings
      rescue Echowrap::Error
        puts "timeout error... retrying"
        retry
      end



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

    def get_itunes_info(attrs)
      attrs[:artist] = I18n.transliterate(attrs[:artist]).gsub('"','')
      attrs[:title] = I18n.transliterate(attrs[:title]).gsub('"','')
      uri = URI.parse('https://itunes.apple.com') + ('search?term=' + (attrs[:artist] + '+' + attrs[:title]).gsub(' ', '+'))
      res = Net::HTTP.get_response(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(req)
      matches = JSON.parse(res.body)["results"]
      jarow = FuzzyStringMatch::JaroWinkler.create( :native )
      matches.each do |match|
        artist_match = jarow.getDistance(attrs[:artist].downcase, ((match["artistName"] || '').downcase))
        title_match = jarow.getDistance(attrs[:title].downcase, ((match["trackName"] || '').downcase))
        if (artist_match > 0.9) && (title_match > 0.9)
          return { album_artwork_url: match["artworkUrl100"].gsub('100x100-75.jpg','600x600-75.jpg'),
                    itunes_track_view_url: match["trackViewUrl"] }
        end
      end
      return nil
    end

  end
end