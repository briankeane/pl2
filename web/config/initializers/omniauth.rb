Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, TWITTER_KEYS['CONSUMER_KEY'], TWITTER_KEYS['CONSUMER_SECRET']
end