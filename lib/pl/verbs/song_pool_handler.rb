require 'json'
require 'echowrap'

module PL
  class SongPoolHandler
    def add_songs(*song_objects)

      # if it's only one, format put it in an array
      if song_objects.is_a?(PL::Song)
        song_object = song_objects
        song_objects = []
        song_objects.push(song_object)
      end

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
      profile = Echowrap.taste_profile_read(id: ECHONEST_KEYS['TASTE_PROFILE_ID'])
      
      all_songs = profile.items.map do |item|

        Song.new({ artist: item.attrs[:item_keyvalues][:pl_artist],
                    title: item.attrs[:item_keyvalues][:pl_title],
                    album: item.attrs[:item_keyvalues][:pl_album],
                    duration: item.attrs[:item_keyvalues][:pl_duration].to_i,
                    key: item.attrs[:item_keyvalues][:pl_key],
                    echonest_id: item.song_id })
      end
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
  end
end