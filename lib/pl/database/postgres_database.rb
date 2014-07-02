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
        has_many :spin_frequencies
      end

      class CommercialBlock < AudioBlock
        has_many :spins
      end

      class Spin < ActiveRecord::Base
        has_one :audio_block
        belongs_to :station
      end

      class Station < ActiveRecord::Base
        belongs_to :user
        has_many :spin_frequencies
        has_many :spins
      end

      class User < ActiveRecord::Base
        has_one :station
      end

      class SpinFrequency < ActiveRecord::Base
        belongs_to :station
        belongs_to :song
      end


      #################
      #     Users     #
      #################
      def create_user(attrs)
        ar_user = User.create(attrs)
        ar_user.save
        user = PL::User.new(ar_user.attributes)
        user
      end

      def get_user(id)
        if User.exists?(id)
          ar_user = User.find(id)
          return PL::User.new(ar_user.attributes)
        else
          return nil
        end
      end

      def get_user_by_twitter(twitter)
        if User.exists?(twitter: twitter)
          ar_user = User.find_by(twitter: twitter)
          return PL::User.new(ar_user.attributes)
        else
          return false
        end
      end

      def get_user_by_twitter_uid(twitter_uid)
        if User.exists?(twitter_uid: twitter_uid)
          ar_user = User.find_by(twitter_uid: twitter_uid)
          return PL::User.new(ar_user.attributes)
        else
          return false
        end
      end

      def update_user(attrs)
        if User.exists?(attrs[:id])
          ar_user = User.find(attrs.delete(:id))
          ar_user.update_attributes(attrs)
          ar_user.save
          return PL::User.new(ar_user.attributes)
        else
          return nil
        end
      end

      def delete_user(id)
        if User.exists?(id)
          ar_user = User.find(id)
          user = PL::User.new(ar_user.attributes)
          User.delete(id)
          return user
        else
          return nil
        end
      end
    end
  end
end
