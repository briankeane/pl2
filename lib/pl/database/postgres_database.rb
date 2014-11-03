require 'active_record'
require 'yaml'
require 'securerandom'

module PL
  module Database

    def self.db
      @__db_instance ||= PostgresDatabase.new(ENV['RAILS_ENV'])
    end

    class PostgresDatabase

      def initialize(env)
        config_path = File.join(File.dirname(__FILE__), '../../../db/config.yml')
        db_config = YAML.load ERB.new(File.read config_path).result
        print "  -- USING: #{env} - #{YAML.load_file(config_path)[env]}"  
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
        has_one :schedule
        has_many :log_entries
      end

      class Schedule < ActiveRecord::Base
        belongs_to :station
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

      class Session < ActiveRecord::Base
        belongs_to :user
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
          spin_frequencies = self.spin_frequencies.pluck(:song_id, :spins_per_week)
          if spin_frequencies
            spin_frequencies.each do |sf|
              spins_per_week[sf[0]] = sf[1]
            end
          end

          if spins_per_week.size > 0
            attrs[:spins_per_week] = spins_per_week
          end

          station = PL::Station.new(attrs)
          return station
        end
      end

      class LogEntry
        def to_pl
          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[self.attributes.map{ |k, v| [k.to_sym, v] }]

          log_entry = PL::LogEntry.new(attrs)
          log_entry
        end
      end

      class Schedule
        def to_pl
          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[self.attributes.map{ |k, v| [k.to_sym, v] }]

          schedule = PL::Schedule.new(attrs)
          schedule
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
          return nil
        end
      end

      def get_user_by_twitter_uid(twitter_uid)
        if User.exists?(twitter_uid: twitter_uid)
          ar_user = User.find_by(twitter_uid: twitter_uid)
          return ar_user.to_pl
        else
          return nil
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

      def get_all_users
        ar_users = User.all.order('twitter ASC')
        users = ar_users.map { |x| x.to_pl }
        ar_users
      end

      def destroy_all_users
        User.delete_all
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
        if Song.where(["LOWER(title) = ? and LOWER(artist) = ?", attrs[:title].downcase, attrs[:artist].downcase]).size > 0
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

      def get_song_by_echonest_id(echonest_id)
        ar_song = Song.find_by('echonest_id = ?', echonest_id)
        
        if !ar_song
          return nil
        end
        
        ar_song.to_pl
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

      def get_station_by_uid(user_id)
        ar_station = Station.find_by('user_id = ?', user_id)
        if ar_station
          return ar_station.to_pl
        else
          return nil
        end
      end

      def destroy_all_stations
        Station.destroy_all
      end

      ###################
      #  SpinFrequency  #
      ###################
      def create_spin_frequency(attrs)   # also updates
        spin_frequency = SpinFrequency.find_by(:station_id =>  attrs[:station_id], :song_id => attrs[:song_id])
        if spin_frequency
          spin_frequency.update_attributes(attrs)
          spin_frequency.save
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

      def destroy_all_spin_frequencies
        SpinFrequency.delete_all
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

      def playlist_exists?(schedule_id)
        Spin.exists?(:schedule_id => schedule_id)
      end

      def delete_spin(id)
        ar_spin = Spin.find(id).destroy
        ar_spin.to_pl
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

      def get_last_spin(schedule_id)
        if Spin.exists?(:schedule_id => schedule_id)
          ar_spin = Spin.where('schedule_id = ?', schedule_id).order(:current_position).last
          return ar_spin.to_pl
        else
          return nil
        end
      end

      def get_next_spin(schedule_id)
        if Spin.exists?(:schedule_id => schedule_id)
          ar_spin = Spin.where('schedule_id = ?', schedule_id).order(:current_position).first
          return ar_spin.to_pl
        else
          return nil
        end
      end

      def get_spin_after_next(schedule_id)
        if Spin.exists?(:schedule_id => schedule_id)
          ar_spin = Spin.where('schedule_id = ?', schedule_id).order(:current_position)[1]
          return ar_spin.to_pl
        else
          return nil
        end
      end

      #################################################################
      #                       add_spin                                #
      #################################################################
      # add_spin adds a spin to the playlist, but instead of deleting #
      # a spin to counterbalance it, it shifts all following spins    #
      # for the rest of the entire playlist                           #
      #################################################################
      def add_spin(attrs)
        # shift everything after
        Spin.where("schedule_id = ? and current_position >= ?", attrs[:schedule_id], attrs[:add_position]).update_all("current_position = current_position + 1")

        # add the new spin into the newly emptied slot
        spin = self.create_spin({ schedule_id: attrs[:schedule_id],
                       current_position: attrs[:add_position],
                       audio_block_id: attrs[:audio_block_id] })
        
        spin
      end

      def get_full_playlist(schedule_id)
        ar_spins = Spin.where(:schedule_id => schedule_id).order(:current_position)
        spins = ar_spins.map{ |ar_spin| ar_spin.to_pl }
        spins
      end

      def get_partial_playlist(attrs)
        case 
        when !attrs[:start_time]
          ar_spins = Spin.where('schedule_id = ? and estimated_airtime <= ?', attrs[:schedule_id], attrs[:end_time]).order(:current_position)
        when !attrs[:end_time]
          ar_spins = Spin.where('schedule_id = ? and estimated_airtime >= ?', attrs[:schedule_id], attrs[:start_time]).order(:current_position)
        else
          ar_spins = Spin.where('schedule_id = ? and estimated_airtime >= ? and estimated_airtime <= ?', attrs[:schedule_id], attrs[:start_time], attrs[:end_time]).order(:current_position)
        end
        
        spins = ar_spins.map { |ar_spin| ar_spin.to_pl }
        spins
      end

      def get_playlist_by_current_positions(attrs)
        if !attrs[:ending_current_position]
          ar_spins = Spin.where('schedule_id = ? and current_position >= ?', attrs[:schedule_id], attrs[:starting_current_position]).order(:current_position)
        else
          ar_spins = Spin.where('schedule_id = ? and current_position >= ? and current_position <= ?', attrs[:schedule_id], attrs[:starting_current_position], attrs[:ending_current_position]).order(:current_position)
        end

        spins = ar_spins.map { |ar_spin| ar_spin.to_pl }
        spins
      end

      def remove_spin(attrs) # schedule_id, current_position
        spin = self.get_spin_by_current_position({ schedule_id: attrs[:schedule_id], current_position: attrs[:current_position] })
        removed_spin = self.delete_spin(spin.id)

        # decrement all following current_positions
        Spin.where("current_position > ?", attrs[:current_position]).update_all("current_position = current_position - 1")

        removed_spin
      end

      def get_final_spin(schedule_id)
        Spin.where("schedule_id = ?", schedule_id).order(:current_position).last
      end

      def get_spin_by_current_position(attrs)
        if Spin.exists?(:schedule_id => attrs[:schedule_id], :current_position => attrs[:current_position])
          ar_spin = Spin.find_by(:schedule_id => attrs[:schedule_id], :current_position => attrs[:current_position])
          spin = self.get_spin(ar_spin.id)
          return spin
        else
          return nil
        end
      end

      ################################################
      # mass_add_spins (csv_file)                    #
      ################################################
      # inserts many spins at once in order to speed #
      # up schedule#generate_playlist -- takes an    #
      # array of Spins and persists them             #
      ################################################
      def mass_add_spins(spins)
        stringified_spins = spins.map { |spin| (spin.schedule_id.to_s + ', ' + 
                                                spin.audio_block_id.to_s + ', ' + 
                                                spin.current_position.to_s + ', ' + 
                                                spin.estimated_airtime.utc.to_s + ', ' + 
                                                Time.now.utc.to_s + ', ' + 
                                                Time.now.utc.to_s) }

        temp_csv_file = Tempfile.new('tempfile.csv')
        begin
          temp_csv_file.write(stringified_spins.join("\n"))
          temp_csv_file.rewind


          conn = ActiveRecord::Base.connection
          rc = conn.raw_connection
          rc.exec("COPY spins (schedule_id, audio_block_id, current_position, estimated_airtime, created_at, updated_at) FROM STDIN WITH CSV")

          while !temp_csv_file.eof?
            rc.put_copy_data(temp_csv_file.readline)
          end

          rc.put_copy_end

          while res = rc.get_result
            if e_message = res.error_message
              p e_message
            end
          end

        ensure
          temp_csv_file.close
          temp_csv_file.unlink
        end
      end

      ####################################
      # move_spin                        #
      # -------------------------------- #
      # takes old_position, new_position #
      # returns true for success, false  #
      # for failure                      #
      ####################################
      def move_spin(attrs)   #old_position, new_position, schedule_id
        spin_to_move = Spin.find_by(:schedule_id => attrs[:schedule_id],
                                    :current_position => attrs[:old_position])

        #if moving backwards
        if attrs[:old_position] > attrs[:new_position]
          Spin.where("schedule_id = ? and current_position >= ? and current_position <= ?", 
                                    attrs[:schedule_id], 
                                    attrs[:new_position], 
                                    attrs[:old_position]).update_all("current_position = current_position + 1")

        elsif attrs[:old_position] < attrs[:new_position]
          Spin.where("schedule_id = ? and current_position >= ? and current_position <= ?", 
                                    attrs[:schedule_id], 
                                    attrs[:old_position], 
                                    attrs[:new_position]).update_all("current_position = current_position - 1")
        else
          # return false if nothing was moved
          return false
        end
        
        spin_to_move.current_position = attrs[:new_position]
        spin_to_move.save
        
        # return true for successful move
        return true
      end

      def destroy_all_spins
        Spin.delete_all
      end

      ##################
      #   log_entries  #   
      ##################
      def create_log_entry(attrs)
        ar_log_entry = LogEntry.create(attrs)
        ar_log_entry.to_pl
      end

      def get_log_entry(id)
        if LogEntry.exists?(id)
          ar_log_entry = LogEntry.find(id)

          return ar_log_entry.to_pl
        else
          return nil
        end
      end

      def get_recent_log_entries(attrs)
        ar_entries = LogEntry.where('station_id = ?', attrs[:station_id]).order('airtime DESC').first(attrs[:count])
        ar_entries.map { |ar_entry| ar_entry.to_pl }
      end

      def get_full_station_log(station_id)
        ar_entries = LogEntry.where('station_id = ?', station_id).order('airtime DESC')
        return ar_entries.map { |ar_entry| ar_entry.to_pl }
      end

      def update_log_entry(attrs)
        if LogEntry.exists?(attrs[:id])
          ar_log_entry = LogEntry.find(attrs.delete(:id))
          ar_log_entry.update_attributes(attrs)
          return ar_log_entry.to_pl
        else
          return nil
        end
      end

      def destroy_all_log_entries
        LogEntry.delete_all
      end

      def log_exists?(station_id)
        LogEntry.exists?(:station_id => station_id)
      end


      ###############
      #  Schedules  #
      ###############
      def create_schedule(attrs)
        ar_schedule = Schedule.create(attrs)
        ar_schedule.save
        ar_schedule.to_pl
      end

      def get_schedule(id)
        if Schedule.exists?(id)
          ar_schedule = Schedule.find(id)
          return ar_schedule.to_pl
        else
          return nil
        end
      end

      def update_schedule(attrs)
        if Schedule.exists?(attrs[:id])
          ar_schedule = Schedule.find(attrs.delete(:id))
          ar_schedule.update_attributes(attrs)
          return ar_schedule.to_pl
        else
          return nil
        end

      end

      def delete_schedule(id)
        if Schedule.exists?(id)
          ar_schedule = Schedule.find(id)
          schedule = ar_schedule.to_pl
          ar_schedule.delete
          return schedule
        else
          return nil
        end
      end

      def destroy_all_schedules
        Schedule.delete_all
      end


      ##############
      #  Sessions  #
      ##############

      def create_session(user_id)
        session_id = SecureRandom.uuid
        Session.create({ user_id: user_id, session_id: session_id })
        return session_id
      end

      def get_uid_by_sid(session_id)
        if Session.exists?(:session_id => session_id)
          session = Session.find_by('session_id = ?', session_id)
          return session.user_id
        else
          return nil
        end
      end

      def get_sid_by_uid(user_id)
        if Session.exists?(:user_id => user_id.to_s)
          session = Session.find_by('user_id = ?', user_id)
          return session.session_id
        else
          return nil
        end
      end

      def delete_session(session_id)
        if Session.exists?(session_id: session_id)
          session = Session.find_by session_id: session_id
          session.delete
          return true
        else
          return nil
        end
      end
    end
  end
end
