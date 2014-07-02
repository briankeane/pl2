require 'active_record'
require 'yaml'

module PL
  module Database

    def self.db
      @__db_instance ||= PostgresDatabase.new(env)
    end

    class PostgresDatabase
      def initialize(env)
        config_path = File.join(File.dirname(__FILE__), '../../../db/config.yml')
        db_config = YAML.load ERB.new(File.read 'db/config.yml').result
        puts "USING: #{env} - #{YAML.load_file(config_path)[env]}"
        ActiveRecord::Base.establish_connection(db_config[env])
      end

      def clear_everything
        ActiveRecord::Base.subclasses.each(&:delete_all)
      end

      #######################
      # ActiveRecord Models #
      #######################
      class AudioBlock < ActiveRecord::Base
        belongs_to :spin
      end

      class Commentary < AudioBlock
      end

      class Song < AudioBlock
        has_many :rotation_levels
      end



    end
  end
end
