require 'active_record'
require 'yaml'

module PL
  module Database

    def self.db
      @__db_instance ||= PostgresDatabase.new(ENV['RAILS_ENV'])
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

      class LogEntry < ActiveRecord::Base
        has_one :station
        has_one :audio_block
      end

      ########################
      # ActiveRecord Methods #
      ########################

      class User
        def to_pl
          PL::User.new(self.attributes)
        end
      end

      class Song
        def to_pl
          PL::Song.new(self.attributes)
        end
      end

      class Commentary
        def to_pl
          PL::Commentary.new(self.attributes)
        end
      end

      class Commercial
        def to_pl
          commercial = PL::Commercial.new(self.attributes)
          commercial
        end
      end

      class CommercialBlock
        def to_pl
          links = CommercialLink.where('audio_block_id = ?', self.id)
          commercials = links.map { |link| PL::Database.db.get_commercial(link.commercial_id) }
          attrs = self.attributes
          attrs[:commercials] = commercials
          cb = PL::CommercialBlock.new(attrs)
          cb
        end
      end

      class Spin
        def to_pl
          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[self.attributes.map{ |k, v| [k.to_sym, v] }]
          
          spin = PL::Spin.new(attrs)
          spin
        end
      end

      class Station
        def to_pl

          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[self.attributes.map{ |k, v| [k.to_sym, v] }]
          
          spins_per_week = {}
          spin_frequencies = SpinFrequency.where('station_id = ?', id)
          if spin_frequencies
            spin_frequencies.each do |sf|
              spins_per_week[sf.song_id] = sf.spins_per_week
            end
          end

          if spins_per_week.size > 0
            attrs[:spins_per_week] = spins_per_week
          end

          station = PL::Station.new(attrs)
          return station
        end
      end


      #################
      #     Users     #
      #################
      def create_user(attrs)
        ar_user = User.create(attrs)
        ar_user.save
        ar_user.to_pl
      end

      def get_user(id)
        if User.exists?(id)
          ar_user = User.find(id)
          return ar_user.to_pl
        else
          return nil
        end
      end

      def get_user_by_twitter(twitter)
        if User.exists?(twitter: twitter)
          ar_user = User.find_by(twitter: twitter)
          return ar_user.to_pl
        else
          return false
        end
      end

      def get_user_by_twitter_uid(twitter_uid)
        if User.exists?(twitter_uid: twitter_uid)
          ar_user = User.find_by(twitter_uid: twitter_uid)
          return ar_user.to_pl
        else
          return false
        end
      end

      def update_user(attrs)
        if User.exists?(attrs[:id])
          ar_user = User.find(attrs.delete(:id))
          ar_user.update_attributes(attrs)
          ar_user.save
          return ar_user.to_pl
        else
          return nil
        end
      end

      def delete_user(id)
        if User.exists?(id)
          ar_user = User.find(id)
          user = ar_user.to_pl
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
          case 
          when ar_audio_block.type.include?('CommercialBlock')
            return self.get_commercial_block(id)
          when ar_audio_block.type.include?('Song')
            return self.get_song(id)
          when ar_audio_block.type.include?('Commentary')
            return self.get_commentary(id)
          end
        end
      end

      ##############
      #   Songs    #
      ##############
      def create_song(attrs)
        ar_song = Song.create(attrs)
        ar_song.to_pl
      end

      def get_song(id)
        if Song.exists?(id)
          ar_song = Song.find(id)
          return ar_song.to_pl
        else
          return nil
        end
      end

      def update_song(attrs)
        if Song.exists?(attrs[:id])
          ar_song = Song.find(attrs.delete(:id))
          ar_song.update_attributes(attrs)
          return ar_song.to_pl
        else
          return false
        end
      end

      def delete_song(id)
        if Song.exists?(id)
          ar_song = Song.find(id)
          song = ar_song.to_pl
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
        ar_songs.each { |ar_song| songs << ar_song.to_pl }
        
        songs
      end

      def get_songs_by_artist(artist)
        ar_songs = Song.where('artist LIKE ?', artist + "%").order('title ASC')
        songs = []
        ar_songs.each { |ar_song| songs << ar_song.to_pl }
        songs
      end

      def get_all_songs
        ar_songs = Song.all.order('artist ASC, title ASC')

        songs = ar_songs.map { |ar_song| ar_song.to_pl }
          
        songs
      end

      #################
      # Commentaries  #
      #################
      def create_commentary(attrs)
        ar_commentary = Commentary.create(attrs)
        ar_commentary.to_pl
      end

      def get_commentary(id)
        if Commentary.exists?(id)
          ar_commentary = Commentary.find(id)
          return ar_commentary.to_pl
        else
          return nil
        end
      end

      def update_commentary(attrs)
        if Commentary.exists?(attrs[:id])
          ar_commentary = Commentary.find(attrs.delete(:id))
          ar_commentary.update_attributes(attrs)
          return ar_commentary.to_pl
        else
          return nil
        end
      end

      def delete_commentary(id)
        if Commentary.exists?(id)
          ar_commentary = Commentary.find(id)
          commentary = ar_commentary.to_pl
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
        ar_commercial.to_pl
      end

      def delete_commercial(id)
        if Commercial.exists?(id)
          ar_commercial = Commercial.find(id)
          commercial = ar_commercial.to_pl
          ar_commercial.delete
          return commercial
        else
          return nil
        end
      end

      def get_commercial(id)
        if Commercial.exists?(id)
          ar_commercial = Commercial.find(id)
          return ar_commercial.to_pl
        else
          return nil
        end
      end

      def update_commercial(attrs)
        if Commercial.exists?(attrs[:id])
          ar_commercial = Commercial.find(attrs.delete(:id))
          ar_commercial.update_attributes(attrs)
          return ar_commercial.to_pl
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

        ar_cb.to_pl
      end

      def get_commercial_block(id)
        if CommercialBlock.exists?(id)
          ar_cb = CommercialBlock.find(id)
          return ar_cb.to_pl
        else
          return nil
        end
      end

      def update_commercial_block(attrs)   # for updating commercials use add_commercial_to_block or delete_commercial_from_block
        if CommercialBlock.exists?(attrs[:id])
          ar_cb = CommercialBlock.find(attrs.delete(:id))
          ar_cb.update_attributes(attrs)
          ar_cb.save
          return ar_cb.to_pl
        else
          return nil
        end
      end

      def delete_commercial_block(id)
        if CommercialBlock.exists?(id)
          ar_cb = CommercialBlock.find(id)
          cb = ar_cb.to_pl

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


      ##############
      #  Stations  #
      ##############
      def create_station(attrs)
        ar_station = Station.create(attrs)
        ar_station.save

        if attrs[:spins_per_week]
          attrs[:spins_per_week].each do |k,v|
            SpinFrequency.create({ station_id: ar_station.id, 
                                    song_id: k,
                                    spins_per_week: v })
          end
        end

        ar_station.to_pl
      end

      def get_station(id)
        if Station.exists?(id)
          ar_station = Station.find(id)
          return ar_station.to_pl
        else
          return nil
        end
      end

      def update_station(attrs)   # for updating spinfrequencies use update_spin_frequency
        if Station.exists?(attrs[:id])
          ar_station = Station.find(attrs.delete(:id))
          ar_station.update_attributes(attrs)

          return self.get_station(ar_station.id)
        else
          return nil
        end
      end

      def get_station_by_user_id(user_id)
        ar_station = Station.find_by('user_id = ?', user_id)
        if ar_station
          return ar_station.to_pl
        else
          return nil
        end
      end

      ###################
      #  SpinFrequency  #
      ###################
      def record_spin_frequency(attrs)
        spin_frequency = SpinFrequency.find_by(:station_id =>  attrs[:station_id], :song_id => attrs[:song_id])
        if spin_frequency
          spin_frequency.update_attributes(attrs)
        else
          spin_frequency = SpinFrequency.create(attrs)
          spin_frequency.save
        end
        return self.get_station(attrs[:station_id])
      end

      def delete_spin_frequency(attrs)
        spin_frequency = SpinFrequency.find_by(:station_id =>  attrs[:station_id], :song_id => attrs[:song_id])
        if spin_frequency
          spin_frequency.delete
        end
        return self.get_station(attrs[:station_id])
      end

      ###############
      #   spins     #
      ###############
      def create_spin(attrs)
        ar_spin = Spin.create(attrs)
        ar_spin.save
        ar_spin.to_pl
      end

      def get_spin(id)
        if Spin.exists?(id)
          ar_spin = Spin.find(id)
          return ar_spin.to_pl
        else
          return nil
        end
      end

      def delete_spin(id)
        ar_spin = Spin.find(id)
        spin = ar_spin.to_pl
        ar_spin.delete
        spin
      end

      def update_spin(attrs)
        if Spin.exists?(attrs[:id])
          ar_spin = Spin.find(attrs.delete(:id))

          ar_spin.update_attributes(attrs)
          ar_spin.save

          return ar_spin.to_pl
        else
          return false
        end
      end

      def get_last_spin(station_id)
        if Spin.exists?(:station_id => station_id)
          ar_spin = Spin.where(:station_id == station_id).order(:current_position).last
          return ar_spin.to_pl
        else
          return nil
        end
      end

      ################################################################
      #                        insert_spin                           #
      ################################################################
      # insert_spin inserts a spin into the playlist.                #
      # it also deletes the 1st song after 3am (or 2am the following #
      # day) to counterbalance the inserted song                     #
      #  ----------------------------------------------------------- #
      # takes: station_id, insert_position, audio_block_id           #
      ################################################################
      def insert_spin(attrs)
        station = self.get_station(attrs[:station_id])
        station.update_estimated_airtimes
        playlist = self.get_full_playlist(station.id)
        index = playlist.find_index { |spin| spin.current_position == attrs[:insert_position] }
        current_position_tracker = attrs[:insert_position]

        # if insert happens in the 3am hour, set marker to the following 1am
        if playlist[index].estimated_airtime.hour == 3
          change_hour = 2
        else
          change_hour = 3
        end

        # adjust current_position until change_hour
        while (playlist[index].estimated_airtime.hour != change_hour) && (index < playlist.size)
          self.update_spin({ id: playlist[index].id, 
                            current_position: (playlist[index].current_position + 1) 
                          })
          index += 1
        end

        # delete that spin
        self.delete_spin(playlist[index].id)

        # insert the new spin into the newly emptied slot
        spin = self.create_spin({ station_id: attrs[:station_id],
                       current_position: attrs[:insert_position],
                       audio_block_id: attrs[:audio_block_id] })
        spin
      end


      #################################################################
      #                       add_spin                                #
      #################################################################
      # add_spin adds a spin to the playlist, but instead of deleting #
      # a spin to counterbalance it, it shifts all following spins    #
      # for the rest of the entire playlist                           #
      #################################################################
      def add_spin(attrs)
        station = self.get_station(attrs[:station_id])
        playlist = self.get_full_playlist(station.id)
        index = playlist.find_index { |spin| spin.current_position == attrs[:add_position] }
        current_position_tracker = attrs[:add_position]

        # adjust current_position until change_hour
        while (index < playlist.size)
          self.update_spin({ id: playlist[index].id, 
                            current_position: (playlist[index].current_position + 1) 
                          })
          index += 1
        end

        # add the new spin into the newly emptied slot
        spin = self.create_spin({ station_id: attrs[:station_id],
                       current_position: attrs[:add_position],
                       audio_block_id: attrs[:audio_block_id] })
        spin
      end

      def get_full_playlist(station_id)
        ar_spins = Spin.where(:station_id => station_id).order(:current_position)
        spins = ar_spins.map{ |ar_spin| ar_spin.to_pl }
        spins
      end

      def get_partial_playlist(attrs)
        ar_spins = Spin.where('station_id = ? and estimated_airtime >= ? and estimated_airtime <= ?', attrs[:station_id], attrs[:start_time], attrs[:end_time]).order(:current_position)
        spins = ar_spins.map { |ar_spin| ar_spin.to_pl }
        spins
      end

      def remove_spin(attrs) # station_id, current_position
        playlist = self.get_full_playlist(attrs[:station_id])
        spin = self.get_spin_by_current_position({ station_id: attrs[:station_id], current_position: attrs[:current_position] })
        removed_spin = self.delete_spin(spin.id)

        index = playlist.find_index { |spin| spin.current_position == (attrs[:current_position] + 1) }
        while index < playlist.size
          self.update_spin({ id: playlist[index].id, current_position: (playlist[index].current_position - 1) })
          index += 1
        end

        removed_spin
      end

      def get_spin_by_current_position(attrs)
        ar_spin = Spin.find_by(:station_id => attrs[:station_id], :current_position => attrs[:current_position])
        spin = self.get_spin(ar_spin.id)
        return spin
      end

      ##################
      #   log_entries  #   
      ##################
      def create_log_entry(attrs)
        ar_log_entry = LogEntry.create(attrs)
        log_entry = self.get_log_entry(ar_log_entry.id)
        log_entry
      end

      def get_log_entry(id)
        if LogEntry.exists?(id)
          ar_log_entry = LogEntry.find(id)
          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[ar_log_entry.attributes.map{ |k, v| [k.to_sym, v] }]

          log_entry = PL::LogEntry.new(attrs)
          return log_entry
        else
          return nil
        end
      end

      def get_recent_log_entries(attrs)
        ar_entries = LogEntry.where('station_id = ?', attrs[:station_id]).order('current_position DESC').first(attrs[:count])
        entries = []
        ar_entries.each do |entry| 
          entries.push(PL.db.get_log_entry(entry.id))
        end
        entries
      end
    end
  end
end
