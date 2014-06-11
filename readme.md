# Playola API
This app is the back-end to PlayolaRadio.  It uses an HTTP interface and provides json-formatted responses.

## REQUESTS

### Users
#####create_user
route '/users/create/'
request:
```
{
	"twitter": "BrianKeaneTunes",
	"twitter_uid": 123,
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
#####update_station
route '/songs/:id'  PUT
request:
```
{
	"station_id": 12,
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
#####create_song
route: '/songs/'  POST
```
{
	audio_file: AUDIOFILEHERE
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
#####create_commentary
route: 'station/commentaries/'  POST
request:
```
{
	"audio_blob": audio_blob_here,
	"station_id": 1234,
	"current_position": 198 
}
```
response:
```
{
	"success": true,
	"spin": { "current_position": 76,
			  "audio_block_type": "commentary",
			  "audio_block_id": 75,
			  "estimated_air_time": time  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			}
}
```

#####get_commentary
'commentaries/:id'    GET
response:           
```
// Since a commentary is always contained in a spin, this request
// returns the enclosing spin

{
	"success": true,
	"spin": { "current_position": 76,
			  "audio_block_type": "commentary",
			  "audio_block_id": 75,
			  "estimated_air_time": time  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			}
}
```

### Spins
#####get_playlist (station_id, start_time [,end_time])  (default 2 hrs of spins)
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
			  "audio_block_type": "song",
			  "audio_block_id": 75,
			  "estimated_air_time": time  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 77,
			  "audio_block_type": "commercial",
			  "audio_block_id": 75,
			  "estimated_air_time": time  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 78,
			  "audio_block_type": "commentary",
			  "audio_block_id": 75,
			  "estimated_air_time": time  // (number, secs since 1970)
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
	"audio_block_type": "song",
	"audio_block_id": 75,
	"estimated_air_time": datetime  // (number, secs since 1970)
	"duration": 1783920     // in milliseconds
}
```
#####get_next_spin_with_audio (station_id)
route '/stations/:station_id/get_next_spin_with_audio'   GET
```
{
	"current_position": 76,
	"audio_block_type": "song",
	"audio_block_id": 75,
	"estimated_air_time": datetime  // (number, secs since 1970)
	"duration": 1783920     // in milliseconds
	"audio_blob": "AUDIODATA HERE"
}
```
#####report_spin_played
route '/log/create/'
```
{
	"spin_id": 394,
	"listeners_at_start": 3,
	"listeners_at_finish": 2,
	"current_position": 722,
	"air_time": datetime,
	"audio_block_id": 75,
	"audio_block_type": "song"
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
			"audio_block_id": 75,
			"audio_block_type": "song"
		}
}

```
### Logs
##### get_last_10_spins
route '/logs/:station_id/' GET
response:
```
{
	"success": true,
	"last_10_spins": 
			[{ "current_position": 76,
			  "audio_block_type": "song",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 77,
			  "audio_block_type": "commercial",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 78,
			  "audio_block_type": "commentary",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920        // in milliseconds 
			}]]
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
			  "audio_block_type": "song",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 77,
			  "audio_block_type": "commercial",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920     // in milliseconds
			},
			{ "current_position": 78,
			  "audio_block_type": "commentary",
			  "audio_block_id": 75,
			  "played_at": datetime  // (number, secs since 1970)
			  "duration": 1783920        // in milliseconds 
			}]
}
```

##SCHEMA
```
create_table "users", force: true do |t|
    t.string   "twitter"
    t.string   "email"
    t.string   "password_digest"
   t.string   "birth_year"
    t.string  "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "twitter_uid"
  end

 create_table "stations", force: true do |t|
    t.integer  "seconds_of_commercial_per_hour"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
 end

create_table "songs", force:true do |t|
    t.integer "sing_start"
    t.integer "sing_end"
    t.string  "title"
    t.string  "artist"
    t.string  "album"
    t.integer "duration"
    t.string "key"
end

create_table "commentaries" do |t|
    t.integer "audio_block_id"
    t.integer "station_id"
    t.datetime "created_at"
end

  create_table "commercials", force: true do |t|
    t.integer "audio_block_id"
    t.integer "sponsor_id"
  end

  create_table "sessions", force: true do |t|
    t.string  "session_id"
    t.integer "user_id"
  end

  create_table "logs", force: true do |t|
    t.integer  "station_id"
    t.datetime "played_at"
    t.integer  "audio_block_id"
    t.string   "audio_block_type"
  end

create_table "spin_frequency" force:true do |t|
   t.integer "song_id"
   t.integer "station_id"   
   t.integer "spins_per_week"
   t.integer "listeners_before"
   t.integer "listeners_after"
end

create_table "spins" force:true do |t|
    t.integer "audio_block_id"
    t.integer "station_id"
    t.integer "current_position"
end
```



