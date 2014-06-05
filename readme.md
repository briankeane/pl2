# Playola API
This app is the back-end to PlayolaRadio.  It uses an HTTP interface and provides json-formatted responses.

## REQUESTS

### Users
create_user  (twitter, email, twitter_uid)
get_user (id)
route '/users/:id'   GET
```
{
	"station_id": 1,
	"email": "bob@bob.com",
	"birth_year": "1919",
	"gender": "male",
	"created_at": 1998332213
}
```
get_user_by_twitter(twitter)
route '/users/get_by_twitter'  GET

    * same info as above

get_user_by_twitter_uid(twitter_uid)
route '/users/get_by_twitter_uid'   GET
	* same info as above

### Stations

update_commercial_seconds_per_hour (station_id, commercial_seconds_per_hour)
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
	"success": false,
	"error": ":no_station_found"
}
```

get_station (station_id)
route: '/stations/:id'  GET
response:
```
{
	"seconds_of_commercial_per_hour": 180,
	"user_id": 123
}

```
### Songs
create_song (title, artist, album, duration, key)
/songs/  POST

### log

### Commentaries
create_commentary (station_id, )

### Spins
get_playlist (station_id, datetime)
get_next_spin(station_id)
get_next_spin_with_audio (station_id)









```
$ DB_ENV=test bundle exec rake db:migrate
```
