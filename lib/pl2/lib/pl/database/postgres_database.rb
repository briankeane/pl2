require 'active_record'
require 'yaml'
require 'securerandom'
require 'date'


module PL
  module Database

    def self.db
      @__db_instance ||= PostgresDatabase.new(ENV['RAILS_ENV'])
    end

    class PostgresDatabase

      def initialize(env)

        if ENV['RAILS_ENV'] == 'production'
          config_path = 'config/database.yml'
          puts Dir.pwd
        else
          config_path = File.join(File.dirname(__FILE__), '../../../db/config.yml')
        end

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
        has_many :genres
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
        has_one :station
        has_many :log_entries
        has_many :listening_sessions
      end

      class User < ActiveRecord::Base
        has_one :station
        has_many :listening_sessions
        has_many :twitter_friends
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

      class TwitterFriend < ActiveRecord::Base
        belongs_to :user
        belongs_to :station
      end

      class ListeningSession < ActiveRecord::Base
        belongs_to :station
        belongs_to :user
      end

      class Genre < ActiveRecord::Base
        has_many :audio_blocks
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

      class ListeningSession
        def to_pl
          # collect the attributes, converting keys from strings to symbols
          attrs = Hash[self.attributes.map{ |k, v| [k.to_sym, v] }]
          listening_session = PL::ListeningSession.new(attrs)
          listening_session
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

      def get_commercial_block_by_current_position(attrs)
        ar_cb = CommercialBlock.where(current_position: attrs[:current_position], station_id: attrs[:station_id])

        if ar_cb.exists?
          return ar_cb[0].to_pl
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

      def get_all_stations
        ar_stations = Station.all
        stations = ar_stations.map { |station| station.to_pl }
        stations
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

      def playlist_exists?(station_id)
        Spin.exists?(:station_id => station_id)
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

      def get_last_spin(station_id)
        if Spin.exists?(:station_id => station_id)
          ar_spin = Spin.where('station_id = ?', station_id).order(:current_position).last
          return ar_spin.to_pl
        else
          return nil
        end
      end

      def get_next_spin(station_id)
        if Spin.exists?(:station_id => station_id)
          ar_spin = Spin.where('station_id = ?', station_id).order(:current_position).first
          return ar_spin.to_pl
        else
          return nil
        end
      end

      def get_spin_after_next(station_id)
        if Spin.exists?(:station_id => station_id)
          ar_spin = Spin.where('station_id = ?', station_id).order(:current_position)[1]
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
        Spin.where("station_id = ? and current_position >= ?", attrs[:station_id], attrs[:add_position]).update_all("current_position = current_position + 1")

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
        case 
        when !attrs[:start_time]
          ar_spins = Spin.where('station_id = ? and airtime <= ?', attrs[:station_id], attrs[:end_time]).order(:current_position)
        when !attrs[:end_time]
          ar_spins = Spin.where('station_id = ? and airtime >= ?', attrs[:station_id], attrs[:start_time]).order(:current_position)
        else
          ar_spins = Spin.where('station_id = ? and airtime >= ? and airtime <= ?', attrs[:station_id], attrs[:start_time], attrs[:end_time]).order(:current_position)
        end
        
        spins = ar_spins.map { |ar_spin| ar_spin.to_pl }
        spins
      end

      def get_playlist_by_current_positions(attrs)
        if !attrs[:ending_current_position]
          ar_spins = Spin.where('station_id = ? and current_position >= ?', attrs[:station_id], attrs[:starting_current_position]).order(:current_position)
        else
          ar_spins = Spin.where('station_id = ? and current_position >= ? and current_position <= ?', attrs[:station_id], attrs[:starting_current_position], attrs[:ending_current_position]).order(:current_position)
        end

        spins = ar_spins.map { |ar_spin| ar_spin.to_pl }
        spins
      end

      def remove_spin(attrs) # station_id, current_position
        spin = self.get_spin_by_current_position({ station_id: attrs[:station_id], current_position: attrs[:current_position] })
        removed_spin = self.delete_spin(spin.id)

        # decrement all following current_positions
        Spin.where("current_position > ?", attrs[:current_position]).update_all("current_position = current_position - 1")

        removed_spin
      end

      def delete_spins_for_station(station_id)
        spins = Spin.delete_all(["station_id = ?", station_id])
      end

      def get_final_spin(station_id)
        Spin.where("station_id = ?", station_id).order(:current_position).last
      end

      def get_spin_by_current_position(attrs)
        if Spin.exists?(:station_id => attrs[:station_id], :current_position => attrs[:current_position])
          ar_spin = Spin.find_by(:station_id => attrs[:station_id], :current_position => attrs[:current_position])
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
      # up station#generate_playlist -- takes an    #
      # array of Spins and persists them             #
      ################################################
      def mass_add_spins(spins)
        stringified_spins = spins.map { |spin| (spin.station_id.to_s + ', ' + 
                                                spin.audio_block_id.to_s + ', ' + 
                                                spin.current_position.to_s + ', ' + 
                                                spin.airtime.utc.to_s + ', ' + 
                                                Time.now.utc.to_s + ', ' + 
                                                Time.now.utc.to_s) }

        temp_csv_file = Tempfile.new('tempfile.csv')
        begin
          temp_csv_file.write(stringified_spins.join("\n"))
          temp_csv_file.rewind


          conn = ActiveRecord::Base.connection
          rc = conn.raw_connection
          rc.exec("COPY spins (station_id, audio_block_id, current_position, airtime, created_at, updated_at) FROM STDIN WITH CSV")

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
      def move_spin(attrs)   #old_position, new_position, station_id
        spin_to_move = Spin.find_by(:station_id => attrs[:station_id],
                                    :current_position => attrs[:old_position])

        #if moving backwards
        if attrs[:old_position] > attrs[:new_position]
          Spin.where("station_id = ? and current_position >= ? and current_position <= ?", 
                                    attrs[:station_id], 
                                    attrs[:new_position], 
                                    attrs[:old_position]).update_all("current_position = current_position + 1")

        elsif attrs[:old_position] < attrs[:new_position]
          Spin.where("station_id = ? and current_position >= ? and current_position <= ?", 
                                    attrs[:station_id], 
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

      def get_log_entry_by_current_position(attrs)
        ar_log_entries = LogEntry.where('station_id = ? and current_position = ?', attrs[:station_id], attrs[:current_position])
        log_entries = ar_log_entries.map { |entry| entry.to_pl }
        log_entries = log_entries.select { |entry| !entry.audio_block.is_a?(PL::CommercialBlock) }
        
        if log_entries.size > 0
          return log_entries[0]
        else
          return nil
        end
      end
      
      def get_log_entries_by_date_range(attrs)
        if !attrs[:end_date] then (attrs[:end_date] = attrs[:start_date]) end

        start_datetime = attrs[:start_date].to_time
        end_datetime = (attrs[:end_date] + 1).to_time  # +1 for the next midnight 

        ar_entries = LogEntry.where("station_id = ? and airtime > ? and airtime < ?",
                                        attrs[:station_id],
                                        start_datetime,
                                        end_datetime).order(:airtime)
        entries = ar_entries.map { |entry| entry.to_pl }
        entries
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

      #####################
      #  Twitter Friends  #
      #####################
      def store_twitter_friends(attrs)
        # delete old list
        old_friends = TwitterFriend.where("follower_uid = ?", attrs[:follower_uid])
        old_friends.delete_all
        attrs[:followed_station_ids].each do |station_id|
          twitter_friend = TwitterFriend.create({ follower_uid: attrs[:follower_uid], followed_station_id: station_id })
          twitter_friend.save
        end
      end

      def get_followed_stations_list(follower_uid)
        station_ids = TwitterFriend.where("follower_uid = ?", follower_uid).map { |friend| friend[:followed_station_id] }
        if !station_ids
          return []
        else
          return station_ids.sort
        end
      end
      
      ########################
      #  Listening Sessions  #
      ########################
      def create_listening_session(attrs)
        ar_listening_session = ListeningSession.create(attrs)
        ar_listening_session.to_pl
      end

      def update_listening_session(attrs)
        if ListeningSession.exists?(attrs[:id])
          ar_listening_session = ListeningSession.find(attrs.delete(:id))

          ar_listening_session.update_attributes(attrs)
          ar_listening_session.save

          return ar_listening_session.to_pl
        else
          return false
        end
      end

      def delete_listening_session(id)
        ar_listening_session = ListeningSession.find(id).destroy
        if ar_listening_session
          return ar_listening_session.to_pl
        else
          return nil
        end
      end

      def get_listening_session(id)
        if ListeningSession.exists?(id)
          ar_listening_session = ListeningSession.find(id)
          return ar_listening_session.to_pl
        else
          return nil
        end
      end

      def find_listening_session(attrs)
        ar_listening_session = ListeningSession.where("station_id = ? and user_id = ? and end_time > ?", 
                                                            attrs[:station_id], 
                                                            attrs[:user_id],
                                                            attrs[:end_time] - (60*2))
        if ar_listening_session.size > 0
          return ar_listening_session.first.to_pl
        else
          return nil
        end
      end

      def get_listener_count(attrs)
        if !attrs[:time]
          attrs[:time] = Time.now
        end

        count = ListeningSession.where("station_id = ? and end_time >= ? and start_time <= ?",
                                        attrs[:station_id],
                                        attrs[:time],
                                        attrs[:time]).size
        count
      end

      def destroy_all_listening_sessions
        ListeningSession.destroy_all
      end

      ##################################################################
      #     genres                                                     #
      ##################################################################
      ##################################################################
      #  values: song_id, genres (array)                               #
      ##################################################################
      def store_genres(attrs)
        attrs[:genres].each { |genre| genre.downcase! }
        existing_genres = self.get_genres(attrs[:song_id])
        attrs[:genres].each do |genre|
          if existing_genres.include?(genre) == false
            Genre.create({ song_id: attrs[:song_id], genre: genre })
          end
        end
      end

      def get_genres(song_id)
        genres = Genre.where("song_id = ?", song_id)
        if genres.size == 0
          return []
        else
          return genres.map { |genre_record| genre_record[:genre] }.sort
        end
      end

      def delete_genres(attrs)
        attrs[:genres].each do |genre|
          Genre.where("genre = ? and song_id = ?", genre, attrs[:song_id]).destroy_all
        end
        return self.get_genres(attrs[:song_id])
      end

      def destroy_all_genres
        Genre.destroy_all
      end
    end
  end
end
