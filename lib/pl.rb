require 'dotenv'
require 'pry-debugger'
Dotenv.load

module PL

  # Constants
  HEAVY_ROTATION = 27
  MEDIUM_ROTATION = 17
  LIGHT_ROTATION = 1
  SPINS_WITHOUT_REPEAT = 35

  def self.db
    case ENV['RAILS_ENV']
    when 'test'
      @db_class ||= Database::InMemory
    else
      @db_class ||= Database::PostgresDatabase
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
# require_relative 'pl/use_case.rb'
require_relative 'pl/database/in_memory.rb'
require_relative 'pl/entities/commentary.rb'
# require_relative 'pl/database/postgres_database.rb'
require_relative 'pl/entities/commercial_block.rb'
require_relative 'pl/entities/commercial.rb'
require_relative 'pl/entities/song.rb'
require_relative 'pl/entities/spin.rb'
require_relative 'pl/entities/station.rb'
require_relative 'pl/entities/user.rb'
#Dir[File.dirname(__FILE__) + '/pl/use-cases/*.rb'].each {|file| require_relative file }

