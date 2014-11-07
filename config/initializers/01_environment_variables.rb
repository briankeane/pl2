# if we're on heroku, load from ENV
if ENV['TWITTER_CONSUMER_KEY']
  TWITTER_KEYS = { 'CONSUMER_KEY'=> ENV['TWITTER_CONSUMER_KEY'],
                    'CONSUMER_SECRET'=> ENV['TWITTER_CONSUMER_SECRET'] }
  S3 = { 'ACCESS_KEY_ID' => ENV['S3_ACCESS_KEY_ID'],
        'SECRET_KEY' => ENV['S3_SECRET_KEY'],
        'SONGS_BUCKET' => 'playolasongs',
        'COMMERCIALS_BUCKET' => 'playolacommercials',
        'COMMENTARIES_BUCKET' => 'playolacommentaries',
        'UNPROCESSED_SONGS' => 'playolaunprocessedsongs' }
  FILEPICKER_KEYS = { 'API_KEY' => ENV['FILEPICKER_API_KEY'] }
  ECHONEST_KEYS = { 'API_KEY' => ENV['ECHONEST_API_KEY'],
                     'CONSUMER_KEY' => ENV['ECHONEST_CONSUMER_KEY'],
                     'SHARED_SECRET' => ENV['ECHONEST_SHARED_SECRET'],
                     'TASTE_PROFILE_ID' => ENV['ECHONEST_TASTE_PROFILE_ID'] }
else 
  TWITTER_KEYS = YAML.load_file("#{::Rails.root}/../secrets/twitter_config.yml")[::Rails.env]
  S3 = YAML.load_file("#{::Rails.root}/../secrets/s3_config.yml")[::Rails.env]
  ECHONEST_KEYS = YAML.load_file("#{::Rails.root}/../secrets/echonest_config.yml")[::Rails.env]
  FILEPICKER_KEYS = YAML.load_file("#{::Rails.root}/../secrets/filepicker_config.yml")[::Rails.env]
end