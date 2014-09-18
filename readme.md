# Playola
This app makes broadcasting a real 24-hr radio station effortless and fun.  It also allows you to listen to what other users are broadcasting.


### Users
#####create_user
route '/users/create/'
request:
```
{
  "twitter": "BrianKeaneTunes",
  "twitter_uid": "123",
  "email": "lonesomewhistle@gmail.com",
  "birth_year": 1977,
  "gender": "male"
}
```
response:
```
{
  "success": true,
  "user": {
      "id": 123,
      "twitter": "BrianKeaneTunes",
      "twitter_uid": 10,
      "email": "lonesomewhistle@gmail.com",
      "birth_year": 1977,
      "gender": "male",
      "created_at": datetime,
      "updated_at": datetime
      }
}

```
#####get_user (id)
route '/users/:id'   GET
response:
```
{
  "success": true,
  "user": {
      "id": 123,
      "twitter": "BrianKeaneTunes",
      "twitter_uid": 10,
      "email": "lonesomewhistle@gmail.com",
      "birth_year": 1977,
      "gender": "male",
      "created_at": datetime,
      "updated_at": datetime
      }

}
```
#####get_user_by_twitter(twitter)
route '/users/get_by_twitter'  GET
```
    * same info as above
```
get_user_by_twitter_uid(twitter_uid)
route '/users/get_by_twitter_uid'   GET
```
  * same info as above
```
#####delete_user(id)
route '/users/:id/'   DELETE
response:
```
{
  "success": true,
  "user": {
      "id": 123,
      "twitter": "BrianKeaneTunes",
      "email": "lonesomewhistle@gmail.com",
      "birth_year": 1977,
      "gender": "male",
      "created_at": datetime,
      "updated_at": datetime
      }
}
```
### Stations
#####create_station
request:
```
{
  "user_id": 123,
  "seconds_of_commercial_per_hour": 180,
  "heavy": [23, 43, 25, 26, 37, 58, 14, 26, 15... ],  // (song_ids)
  "medium": [14, 65, 943, 234...],
  "light": [12, 4, 6, 1, 3] 
  }
}
```
response:
```
{
  "success": true,
  "station": {
        "id": 500,
        "seconds_of_commercial_per_hour": 180,
        "user_id": 123,
    "spins_per_week": {     
      // song_id: spins_per_week
      [
      15: 27,
      27: 27,
      84: 27,
      19: 17,
      12: 17,
      11: 17,
      ...
      ]
  }       
}
```
#####update_station
route '/songs/:id'  PUT
request:
```
{
  "id": 12,
  "commercial_seconds_per_hour": 180
}
```
response:
```
{
  "success": true,
  "station": {
    "id": 500,
    "seconds_of_commercial_per_hour": 180,
    "user_id": 123,
    "spins_per_week": {     
      #song_id: spins_per_week
      15: 27,
      27: 25,
      84: 22,
      19: 14,
      12: 3,
      11: 2
  }
}
```
#####get_station (station_id)
route: '/stations/:id'  GET
response:
```
{
  "success": true,
  "station": {
    "id": 500,
    "seconds_of_commercial_per_hour": 180,
    "user_id": 123,
    "spins_per_week": {     
      #song_id: spins_per_week
      15: 27,
      27: 25,
      84: 22,
      19: 14,
      12: 3,
      11: 2
  }
}

```
### Songs
#####process_song
route: '/songs/'  POST
```
{
  "key": 'stepladder.mp3'  // uploaded to amazon s3
}
```
response:
```
{
  "success": true,
  "song": {
    "id": 99,
    "artist": "Rachel Loy",
    "title": "Stepladder",
    "album": "Broken Machine",
    "duration": 196555,
    "key": 'ThisIsAKey.mp3'
  }
}
```
#####get_song
route: '/songs/:id' GET
response:
```
same as above
```
#####get_all_songs
route: '/songs' GET
response:
```
{
    "all_songs": [
    {
    "id": 99,
    "artist": "Rachel Loy",
    "title": "Stepladder",
    "album": "Broken Machine",
    "duration": 196555,
    "key": 'ThisIsAKey.mp3'
    },
    { song 2 .... },
    { song 3 .... }
    ]
}
```
#####get_songs_by_title
route: '/songs_by_title' GET
```
{
  "title": "Step"
}
```
response:
```
same as above
```
#####get_songs_by_artist
route: '/songs_by_artist' GET
request and response:
```
same as above
```
#####update_song
route: 'songs/:id'  PUT
```
{
  "artist": 'Brian Keane'
}
```
response:
```
{
  "success": true,
  "song": {
    "id": 99,
    "artist": "Brian Keane",
    "title": "Stepladder",
    "album": "Broken Machine",
    "duration": 196555,
    "key": 'ThisIsAKey.mp3'
  }
}
```
#####delete_song
route: '/songs/:id' DELETE
response:
```
{
  "success": true,
  "song": {
    "id": 99,
    "artist": "Brian Keane",
    "title": "Stepladder",
    "album": "Broken Machine",
    "duration": 196555,
    "key": 'ThisIsAKey.mp3'
  }
}
```
### spin_frequencies
##### create_spin_frequency
route '/spin_frequencies/'  POST
request:
```
{
  "song_id": 2,
  "station_id": 4,
  "spins_per_week", 17
}
```
response:
```
{
  "success": true,
  "updated_station": { updated station object }
}
```
##### update_spin_frequency
route 'spin_frequencies/' PUT
request/response:
```
same as above. (update with spins_per_week:0 to delete)
```

### log

### Commentaries
#####create_commentary           //(NOT BUILT YET)
route: 'station/commentaries/'  POST
request:
```
{
  "station_id": 1234,
  "current_position": 198,
  "key": 'ThisIsAKey.wav'
  "duration": 5000
}
```
response:
```
{
  "success": true,
  "commentary": { 
        "id": 4,
        "station_id": 5, 
        "duration": 5000,
        "key": 'ThisIsAKey.mp3'
      }
}
```

#####get_commentary
'commentaries/:id'    GET
response:           
```
{
  "success": true,
  "commentary": { 
        "id": 4,
        "station_id": 5, 
        "duration": 5000,
        "key": 'ThisIsAKey.mp3'
        }
}
```
#####update_commentary   // (NOT BUILT YET)
route '/commetaries/:id' PUT
request:
```
{
  "id": 4,
  "key": "AnotherKey.mp3"
}
```
response:
```
{
  "success": true,
  "commentary": { 
        "id": 4,
        "station_id": 5, 
        "duration": 5000,
        "key": 'AnotherKey.mp3'
        }
}
```
#####delete_commentary
route '/commentaries/:id' DELETE
response:
```
{
  "success": true,
  "commentary": { 
        "id": 4,
        "station_id": 5, 
        "duration": 5000,
        "key": 'AnotherKey.mp3'
        }
}
```

### Spins
#####get_playlist (station_id, start_time [end_time])  (default 2 hrs of spins)
request:
```
{
  "station_id": 55,
  "start_time": 12345678,      // (number, secs since 1970 UTC)
    "end_time": 12345878
}
```

response:
```
{
  "spins": [
      { "current_position": 76,
        "audio_block_id": 75,
        "estimated_airtime": time  // (number, secs since 1970)
        "duration": 1783920     // in milliseconds
      },
      { "current_position": 77,
        "audio_block_id": 75,
        "estimated_airtime": time  // (number, secs since 1970)
        "duration": 1783920     // in milliseconds
      },
      { "current_position": 78,
        "audio_block_id": 75,
        "estimated_airtime": time  // (number, secs since 1970)
        "duration": 1783920        // in milliseconds 
      }]
}
```

#####get_next_spin(station_id)
route '/stations/:station_id/get_next_spin'   GET
response:
```
{
  "current_position": 76,
  "audio_block_id": 75,
  "estimated_airtime": datetime  // (number, secs since 1970)
  "duration": 1783920     // in milliseconds
}
```
#####get_next_spin_with_audio (station_id)
route '/stations/:station_id/get_next_spin_with_audio'   GET
```
{
  "current_position": 76,
  "audio_block_id": 75,
  "estimated_airtime": datetime  // (number, secs since 1970)
  "duration": 1783920     // in milliseconds
  "audio_blob": "AUDIODATA HERE"
}
```
#####report_spin
This UseCase also deletes the play from the current_playlist
route '/log/create/' POST
```
{
  "spin_id": 394,
  "listeners_at_start": 3,
  "listeners_at_finish": 2,
  "current_position": 722,
  "air_time": datetime,
  "audio_block_id": 75
}
```
response:
```
{
  "success":true,
  "spin":{ 
      "spin_id": 394,
      "listeners_at_start": 3,
      "listeners_at_finish": 2,
      "current_position": 722,
      "air_time": datetime,
      "audio_block_id": 75
    }
}

```
### 
##### create_log_entry
route: '/log_entries/' PUT


##### get_last_10_plays
route '/log_entries/:station_id/' GET
response:
```
{
  "success": true,
  "last_10_spins": 
      [{ "id": 1,
         "station_id": 4,
         "current_position": 76,
         "audio_block_id": 375,
         "airtime": Time.new(1983, 4, 15, 18),   // (number, secs since 1970)
         "listeners_at_start": 55,       
         "listeners_at_finish": 57  
      },
      { log entry },
      { log entry },
      .... 
      ]
}
```
##### get_log_entry
route: '/log_entries/:id' GET
```
{   "log_entry":     
        {
         "id": 1,
         "station_id": 4,
         "current_position": 76,
         "audio_block_id": 375,
         "airtime": Time.new(1983, 4, 15, 18),   // (number, secs since 1970)
         "listeners_at_start": 55,       
         "listeners_at_finish": 57  
        }
}
```

#### get_full_station_log
route 'logs/full_station_logs'  GET
response:
```
{
  "success": true,
  "full_station_log": 
      [{ "current_position": 76,
        "audio_block_id": 75,
        "played_at": datetime  // (number, secs since 1970)
        "duration": 1783920     // in milliseconds
      },
      { "current_position": 77,
        "audio_block_id": 75,
        "played_at": datetime  // (number, secs since 1970)
        "duration": 1783920     // in milliseconds
      },
      { "current_position": 78,
        "audio_block_id": 75,
        "played_at": datetime  // (number, secs since 1970)
        "duration": 1783920        // in milliseconds 
      }]
}
```

##SCHEMA
```
 create_table "audio_blocks", force: true do |t|
    t.string   "type"
    t.string   "key"
    t.integer  "duration"
    t.datetime "estimated_airtime"
    t.integer  "commentary_preceding_overlap"
    t.integer  "song_preceding_overlap"
    t.integer  "commercial_preceding_overlap"
    t.integer  "commentary_following_overlap"
    t.integer  "commercial_following_overlap"
    t.integer  "song_following_overlap"
    t.integer  "cb_position"
    t.string   "artist"
    t.string   "title"
    t.string   "album"
    t.integer  "station_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commercials", force: true do |t|
    t.integer  "sponsor_id"
    t.integer  "duration"
    t.string   "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_entries", force: true do |t|
    t.string   "type"
    t.integer  "station_id"
    t.integer  "current_position"
    t.integer  "audio_block_id"
    t.datetime "airtime"
    t.integer  "listeners_at_start"
    t.integer  "listeners_at_finish"
    t.integer  "duration"
  end

  create_table "spin_frequencies", force: true do |t|
    t.integer "song_id"
    t.integer "station_id"
    t.integer "spins_per_week"
  end

  create_table "spins", force: true do |t|
    t.integer  "current_position"
    t.integer  "station_id"
    t.datetime "estimated_airtime"
    t.integer  "audio_block_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stations", force: true do |t|
    t.integer  "user_id"
    t.integer  "secs_of_commercial_per_hour"
    t.integer  "spins_per_week"
    t.datetime "current_playlist_end_time"
    t.datetime "original_playlist_end_time"
    t.integer  "next_commercial_block_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "twitter"
    t.integer  "twitter_uid"
    t.string   "email"
    t.integer  "birth_year"
    t.string   "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
```