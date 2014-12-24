TWITTER_KEYS = YAML.load_file("#{::Rails.root}/lib/pl2/secrets/twitter_config.yml")[::Rails.env]
S3 = YAML.load_file("#{::Rails.root}/lib/pl2/secrets/s3_config.yml")[::Rails.env]
ECHONEST_KEYS = YAML.load_file("#{::Rails.root}/lib/pl2/secrets/echonest_config.yml")[::Rails.env]
FILEPICKER_KEYS = YAML.load_file("#{::Rails.root}/lib/pl2/secrets/filepicker_config.yml")[::Rails.env]