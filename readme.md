# Playola API
This app is the back-end to PlayolaRadio.  It uses an HTTP interface and provides json-formatted responses.

## REQUESTS

### Users
create_user  (twitter, email, twitter_uid)
get_user (id)
	* station_id

	* email

	* birth_year

	* gender

	* created_at

get_user_by_twitter(twitter)

    * same info as above

get_user_by_twitter_uid(twitter_uid)

	* same info as above

### Stations

update_commercial_time (station_id, seconds_per_hour)

get_station_info (station_id)

	* seconds_of_commercial_per_hour

	* user_id

	* heavy_rotation  (array of song objects w/out audio blob)

	* medium_rotation  (array of song objects w/out audio blob)

	* light_rotation  (array of song objects w/out audio blob)

### Songs

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
