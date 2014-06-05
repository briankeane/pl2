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
	"song": {
			"user_id": 123,
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
	"station_id": 1,
	"email": "bob@bob.com",
	"birth_year": "1919",
	"gender": "male",
	"created_at": 1998332213
}
```
#####get_user_by_twitter(twitter)
route '/users/get_by_twitter'  GET

    * same info as above

get_user_by_twitter_uid(twitter_uid)
route '/users/get_by_twitter_uid'   GET
	* same info as above

### Stations
#####create_station
request:
```
{
	"user_id": 123,
	"seconds_of_commercial_per_hour": 180,
	"heavy":[{
				"artist": "Rachel Loy",
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555				
			},
			{
				"artist": "Rachel Loy",d
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555	
			},
			{  .... 
			}]
	"medium": [ { song object }, { song object }, etc... ],
	"light" : [ { song object }, { song object }, etc... ]
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
				"heavy":[{
							"artist": "Rachel Loy",
							"title": "Stepladder",
							"album": "Broken Machine",
							"duration": 196555				
						},
						{
							"artist": "Rachel Loy",d
							"title": "Stepladder",
							"album": "Broken Machine",
							"duration": 196555	
						},
						{  .... 
						}]
				"medium": [ { song object }, { song object }, etc... ],
				"light" : [ { song object }, { song object }, etc... ]
				}
}
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
		"heavy":[{
				"artist": "Rachel Loy",
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555				
			},
			{
				"artist": "Rachel Loy",d
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555	
			},
			{  .... 
			}]
				"medium": [ { song object }, { song object }, etc... ],
				"light" : [ { song object }, { song object }, etc... ]
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
		"heavy":[{
				"artist": "Rachel Loy",
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555				
			},
			{
				"artist": "Rachel Loy",d
				"title": "Stepladder",
				"album": "Broken Machine",
				"duration": 196555	
			},
			{  .... 
			}]
				"medium": [ { song object }, { song object }, etc... ],
				"light" : [ { song object }, { song object }, etc... ]
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
{
	"success": true,
	"song": {
		"artist": "Rachel Loy",
		"title": "Stepladder",
		"album": "Broken Machine",
		"duration": 196555
	}
}
### log

### Commentaries
#####create_commentary

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
	"estimated_air_time": time  // (number, secs since 1970)
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
	"estimated_air_time": time  // (number, secs since 1970)
	"duration": 1783920     // in milliseconds
	"audio_blob": "AUDIODATA HERE"
}
```
