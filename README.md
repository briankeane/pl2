== playola.fm

# Installing Locally (for Mac)

1) fork and clone down the repo

2) obtain tokens for: echonest, twitter, s3, and filepicker.io

3) create the folder 'lib/pl2/secrets' and install the following yml files:

echonest_config.yml
```
development:
  API_KEY: xxxxxxxxxxx 
  CONSUMER_KEY: xxxxxxxxxxx 
  SHARED_SECRET: xxxxxxxxxxx
  TASTE_PROFILE_ID: xxxxxxxxxxx

test:
  API_KEY: xxxxxxxxxxx 
  CONSUMER_KEY: xxxxxxxxxxx 
  SHARED_SECRET: xxxxxxxxxxx
  TASTE_PROFILE_ID: xxxxxxxxxxx

production:
  API_KEY: xxxxxxxxxxx 
  CONSUMER_KEY: xxxxxxxxxxx 
  SHARED_SECRET: xxxxxxxxxxx
  TASTE_PROFILE_ID: xxxxxxxxxxx
```
twitter_config.yml
```
development:
  CONSUMER_KEY: xxxxxxxxxxxxxxxxxx
  CONSUMER_SECRET: xxxxxxxxxxxxxxxxxxxxxxx
etc...
```
s3_config.yml
```
development:
  ACCESS_KEY_ID: xxxxxxxxxxxxxx
  SECRET_KEY: xxxxxxxxxxxxxx
  SONGS_BUCKET: playolasongs
  COMMERCIALS_BUCKET: playolacommercials
  COMMENTARIES_BUCKET: playolacommentaries
  UNPROCESSED_SONGS: playolaunprocessedsongs

test:
  ACCESS_KEY_ID: xxxxxxxxxxxxxxxxx
  SECRET_KEY: xxxxxxxxxxxxxxxxxxxxx
  SONGS_BUCKET: playolasongstest
  COMMERCIALS_BUCKET: playolacommercialstest
  COMMENTARIES_BUCKET: playolacommentariestest
  UNPROCESSED_SONGS: playolaunprocessedsongstest

production:
  ACCESS_KEY_ID: xxxxxxxxxxxxxxxxx
  SECRET_KEY: xxxxxxxxxxxxxxxxxxxxx
  SONGS_BUCKET: playolasongs
  COMMERCIALS_BUCKET: playolacommercials
  COMMENTARIES_BUCKET: playolacommentaries
  UNPROCESSED_SONGS: playolaunprocessedsongs
```
filepicker_config.yml
```
development:
  API_KEY: xxxxxxxxxxxxxx

etc.
```

4) Install dependencies.
  ```
  brew install lame
  brew install ffmpeg
  brew install faad2
  brew install sox
  brew install taglib
  brew install postgresql
  ```
5) Bundle install
```
bundle install
```

6) create and migrate database
```
cd lib/pl2/
rake db:create RAILS_ENV=test
rake db:create RAILS_ENV=development
rake db:migrate RAILS_ENV=test
rake db:migrate RAILS_ENV=development
```

7) load db with songs from storage
```
rake db:load_db_via_storage RAILS_ENV=development
```

#Notes
* The core logic code is located in lib/pl2.
* All db rake tasks must be performed from lib/pl2
