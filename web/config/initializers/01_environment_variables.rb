TWITTER_KEYS = YAML.load_file("#{::Rails.root}/../secrets/twitter_config.yml")[::Rails.env]
S3 = YAML.load_file("#{::Rails.root}/../secrets/s3_config.yml")[::Rails.env]
ECHONEST_KEYS = YAML.load_file("#{::Rails.root}/../secrets/echonest_config.yml")[::Rails.env]
FILEPICKER_KEYS = YAML.load_file("#{::Rails.root}/../secrets/filepicker_config.yml")[::Rails.env]