require 'aws'
require 'pry-debugger'

# load environment variables only if RAILS app has not loaded them first
#    -- (this is here so the non-rails app can stand on its own)
if !defined? TWITTER_KEYS
  TWITTER_KEYS = YAML.load_file("secrets/twitter_config.yml")[ENV['RAILS_ENV']]
  S3_KEYS = YAML.load_file("secrets/s3_config.yml")[ENV['RAILS_ENV']]
  ECHONEST_KEYS = YAML.load_file("secrets/echonest_config.yml")[ENV['RAILS_ENV']]
end


module PL

  # set up AWS
  AWS.config(access_key_id: S3_KEYS['ACCESS_KEY_ID'], secret_access_key: S3_KEYS['SECRET_KEY'], region: 'us-west-2')

  
  # Constants
  HEAVY_ROTATION = 27
  MEDIUM_ROTATION = 17
  LIGHT_ROTATION = 1
  SPINS_WITHOUT_REPEAT = 35
  DEFAULT_SECS_OF_COMMERCIAL_PER_HOUR = 360
  MIN_HEAVY_COUNT = 10
  MIN_MEDIUM_COUNT = 10
  MIN_LIGHT_COUNT = 5

  def self.db
    case ENV['RAILS_ENV']
    when 'test'
      @db_class ||= Database::InMemory
    else
      # change this once Postgres DB is installed
      @db_class ||= Database::PostgresDatabase
      #@db_class ||= Database::InMemory
    end
    @__db_instance ||= @db_class.new(ENV['RAILS_ENV'] || 'test')
  end

  def self.db_class=(db_class)
    @db_class = db_class
  end

  def self.env=(env_name)
    @env = env_name
  end

end

require 'ostruct'
require_relative 'pl/entity.rb'
require_relative 'pl/use_case.rb'
require_relative 'pl/database/in_memory.rb'
require_relative 'pl/entities/commentary.rb'
require_relative 'pl/entities/log_entry.rb'
require_relative 'pl/verbs/commercial_block_factory.rb'
require_relative 'pl/verbs/audio_file_grabber.rb'
require_relative 'pl/verbs/song_suggester.rb'
require_relative 'pl/verbs/song_processor.rb'
require_relative 'pl/database/postgres_database.rb'
require_relative 'pl/entities/commercial_block.rb'
require_relative 'pl/entities/commercial.rb'
require_relative 'pl/entities/song.rb'
require_relative 'pl/entities/spin.rb'
require_relative 'pl/entities/station.rb'
require_relative 'pl/entities/user.rb'
Dir[File.dirname(__FILE__) + '/pl/use-cases/*.rb'].each {|file| require_relative file }
Dir[File.dirname(__FILE__) + '/pl/processors/*.rb'].each {|file| require_relative file }
