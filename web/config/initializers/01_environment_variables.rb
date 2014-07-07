TWITTER_KEYS = YAML.load_file("#{::Rails.root}/../secrets/twitter_config.yml")[::Rails.env]
S3_KEYS = YAML.load_file("#{::Rails.root}/../secrets/s3_config.yml")[::Rails.env]
