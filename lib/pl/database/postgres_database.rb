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
        has_many :commercial_links
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

      class Commercial < ActiveRecord::Base
        has_many :commercial_links
        has_many :commercial_blocks, :through => :commercial_links
      end

      class CommercialLink < ActiveRecord::Base
        belongs_to :commercials
        belongs_to :commercial_blocks
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

      ###############################################
      # Audio_Blocks                                #
      ###############################################
      # songs, commercial_blocks, and commentaries  #
      # are all types of audio_blocks               #
      ###############################################
      def get_audio_block(id)
        if AudioBlock.exists?(id)
          ar_audio_block = AudioBlock.find(id)
          case ar_audio_block.type
          when 'commercial_block'
            return self.get_commercial_block(id)
          when 'song'
            return self.get_song(id)
          when 'commentary'
            return self.get_commentary(id)
          end
        end
      end

      ##############
      #   Songs    #
      ##############
      def create_song(attrs)
        ar_song = Song.create(attrs)
        song = PL::Song.new(ar_song.attributes)
        song
      end

      def get_song(id)
        if Song.exists?(id)
          ar_song = Song.find(id)
          song = PL::Song.new(ar_song.attributes)
        else
          return nil
        end
      end

      def update_song(attrs)
        if Song.exists?(attrs[:id])
          ar_song = Song.find(attrs.delete(:id))
          ar_song.update_attributes(attrs)
          song = PL::Song.new(ar_song.attributes)
          return song
        else
          return false
        end
      end

      def delete_song(id)
        if Song.exists?(id)
          ar_song = Song.find(id)
          song = PL::Song.new(ar_song.attributes)
          ar_song.delete
          return song
        else
          return nil
        end
      end

      def song_exists?(attrs)
        if Song.where(["title = ? and artist = ? and album = ?", attrs[:title], attrs[:artist], attrs[:album]]).size > 0
          return true
        else
          return false
        end
      end

      def get_songs_by_title(title)
        ar_songs = Song.where('title LIKE ?', title + "%").order('title ASC')

        songs = []
        ar_songs.each do |song|
          song = PL::Song.new(song.attributes)
          songs << song
        end
        songs
      end

      def get_songs_by_artist(artist)
        ar_songs = Song.where('artist LIKE ?', artist + "%").order('title ASC')
        songs = []
        ar_songs.each do |song|
          song = PL::Song.new(song.attributes)
          songs << song
        end
        songs
      end

      def get_all_songs
        ar_songs = Song.all.order('artist ASC, title ASC')

        songs = ar_songs.map { |song| PL::Song.new(song.attributes) }
          
        songs
      end

      #################
      # Commentaries  #
      #################
      def create_commentary(attrs)
        ar_commentary = Commentary.create(attrs)
        commentary = PL::Commentary.new(ar_commentary.attributes)
      end

      def get_commentary(id)
        if Commentary.exists?(id)
          ar_commentary = Commentary.find(id)
          commentary = PL::Commentary.new(ar_commentary.attributes)
          return commentary
        else
          return nil
        end
      end

      def update_commentary(attrs)
        if Commentary.exists?(attrs[:id])
          ar_commentary = Commentary.find(attrs.delete(:id))
          ar_commentary.update_attributes(attrs)
          commentary = PL::Commentary.new(ar_commentary.attributes)
        else
          return nil
        end
      end

      def delete_commentary(id)
        if Commentary.exists?(id)
          ar_commentary = Commentary.find(id)
          commentary = PL::Commentary.new(ar_commentary.attributes)
          ar_commentary.delete
          return commentary
        else
          return nil
        end
      end

      #################
      # Commercials   #
      #################
      def create_commercial(attrs)
        ar_commercial = Commercial.create(attrs)
        ar_commercial.save
        commercial = PL::Commercial.new(ar_commercial.attributes)
        commercial
      end

      def delete_commercial(id)
        if Commercial.exists?(id)
          ar_commercial = Commercial.find(id)
          commercial = PL::Commercial.new(ar_commercial.attributes)
          ar_commercial.delete
          return commercial
        else
          return nil
        end
      end

      def get_commercial(id)
        if Commercial.exists?(id)
          ar_commercial = Commercial.find(id)
          commercial = PL::Commercial.new(ar_commercial.attributes)
          return commercial
        else
          return nil
        end
      end

      def update_commercial(attrs)
        if Commercial.exists?(attrs[:id])
          ar_commercial = Commercial.find(attrs.delete(:id))
          ar_commercial.update_attributes(attrs)
          commercial = PL::Commercial.new(ar_commercial.attributes)
          return commercial
        else
          return false
        end
      end

      #####################
      # Commercial_Blocks #
      #####################
      def create_commercial_block(attrs)
        commercials = attrs.delete(:commercials)
        ar_cb = CommercialBlock.create(attrs)
        ar_cb.save

        if commercials
          commercials.each do |commercial|
            CommercialLink.create({ audio_block_id: ar_cb.id, commercial_id: commercial.id })
          end
        end

        cb = self.get_commercial_block(ar_cb.id)
        cb
      end

      def get_commercial_block(id)
        if CommercialBlock.exists?(id)
          ar_cb = CommercialBlock.find(id)

          links = CommercialLink.where('audio_block_id = ?', id)
          commercials = links.map { |link| self.get_commercial(link.commercial_id) }
          attrs = ar_cb.attributes
          attrs[:commercials] = commercials 
          cb = PL::CommercialBlock.new(attrs)
          cb
        else
          return nil
        end
      end

      def update_commercial_block(attrs)   # for updating commercials use add_commercial_to_block or delete_commercial_from_block
        if CommercialBlock.exists?(attrs[:id])
          ar_cb = CommercialBlock.find(attrs.delete(:id))
          ar_cb.update_attributes(attrs)

          return self.get_commercial_block(ar_cb.id)
        else
          return nil
        end
      end

      def delete_commercial_block(id)
        if CommercialBlock.exists?(id)
          ar_cb = CommercialBlock.find(id)
          cb = self.get_commercial_block(id)

          # if there are commercials, delete commercial_links
          if cb.commercials.size > 0
            commercial_links = CommercialLink.where('audio_block_id = ?', id)
            commercial_links.each { |link| link.delete }
          end

          ar_cb.delete

          return cb
        else
          return nil
        end
      end





    end
  end
end
