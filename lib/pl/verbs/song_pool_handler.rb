require 'json'
require 'echowrap'

module PL
  class SongPoolHandler

    def add_song(song_object)
      self.add_songs(song_object)
    end

    def add_songs(*song_objects)

      # This allows 1 object, a list, or an array of objects to be passed
      if song_objects.is_a?(PL::Song)
        song_objects = [song_objects]
      elsif song_objects[0].is_a?(Array)
        song_objects = song_objects[0]
      end

      # delete songs that are already in the song_pool
      song_objects.delete_if { |song| self.song_included?({ artist: song.artist, title: song.title })}
      
      total_to_add = song_objects.count
      
      # while they have not yet all been added
      while (song_objects.size > 0)

        json_songs = song_objects.map do |song|
          ({    "item" => {
                  "item_id"=> song.key,
                  "song_id"=> song.echonest_id,
                  "item_keyvalues"=> {
                    "pl_artist"=> song.artist,
                    "pl_key"=> song.key,
                    "pl_title"=> song.title,
                    "pl_album"=> song.album,
                    "pl_duration"=> song.duration
                  }
                }
            }).to_json
        end

        data = '[' + json_songs.join(", \n") + ']'

        Echowrap.taste_profile_update(id: ECHONEST_KEYS['TASTE_PROFILE_ID'], data: data)

        # remove songs that have been added
        song_objects.delete_if { |song| self.song_included?({ artist: song.artist, title: song.title }) }
      end
    end

    def delete_song(item_id)
      data =    ({ "action" => "delete",
                  "item" => {
                    "item_id" => item_id
                  }
                }).to_json

      data = '[' + data + ']'
      Echowrap.taste_profile_update(id: ECHONEST_KEYS['TASTE_PROFILE_ID'], data: data)
    end

    def all_songs

      index = 0
      items = []
      
      # keep making calls while the max number of allowed answers is returned
      begin
        new_items = Echowrap.taste_profile_read(id: ECHONEST_KEYS['TASTE_PROFILE_ID'], results: 1000, start: index).items
        items.concat(new_items)
        index += 1000
      end while (new_items.size == 1000)

      all_songs = items.map do |item|

        Song.new({ artist: item.attrs[:item_keyvalues][:pl_artist],
                    title: item.attrs[:item_keyvalues][:pl_title],
                    album: item.attrs[:item_keyvalues][:pl_album],
                    duration: item.attrs[:item_keyvalues][:pl_duration].to_i,
                    key: item.attrs[:item_keyvalues][:pl_key],
                    echonest_id: item.song_id })
      end

      all_songs
    end

    def clear_all_songs
      profile = Echowrap.taste_profile_read(id: ECHONEST_KEYS['TASTE_PROFILE_ID'])
      json_songs = profile.items.map do |item|
        ({ "action" => "delete",
            "item" => {
              "item_id" => item.request.item_id
              }
          }).to_json
      end

      data = '[' + json_songs.join(", \n") + ']'

      Echowrap.taste_profile_update(id: ECHONEST_KEYS['TASTE_PROFILE_ID'], data: data)
    end

    ########################################################
    #                  song_included?(attrs)               #
    ########################################################
    # takes title and artist and returns true if song is   #
    # included in the pool.                                #
    ########################################################
    def song_included?(attrs)
      songs =self.all_songs

      songs.select { |song| (song.artist == attrs[:artist]) && 
                                    (song.title == attrs[:title]) }
      if songs.size > 0
        return true
      else
        return false
      end
    end
  end
end