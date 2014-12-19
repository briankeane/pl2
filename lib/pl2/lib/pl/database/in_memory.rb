require 'zlib'
require 'csv'
require 'securerandom'

module PL
  module Database

    def self.db
      @__db_instance ||= InMemory.new
    end

    class InMemory

      def initialize(env=nil)
        clear_everything
      end

      def clear_everything
        @user_id_counter = 100
        @users = {}
        @station_id_counter = 300
        @stations = {}
        @spin_counter = 700
        @spins = {}
        @log_entry_counter = 800
        @log_entries = {}
        @audio_block_counter = 900
        @audio_blocks = {}
        @sessions = {}
        @twitter_friends = {}
        @listening_sessions = {}
        @listening_session_counter = 200
        @genre_id_counter = 150
        @genres = {}
      end

      ##############
      #   Users    #
      ##############
      def create_user(attrs)
        id = (@user_id_counter += 1)
        attrs[:id] = id
        attrs[:created_at] = Time.now
        attrs[:updated_at] = Time.now
        user = User.new(attrs)
        @users[id] = user
        user
      end

      def get_user(id)
        @users[id]
      end

      def get_user_by_twitter(twitter)
        @users.values.find { |user| user.twitter == twitter }
      end

      def get_user_by_twitter_uid(uid)
        @users.values.find { |user| user.twitter_uid == uid }
      end
      
      def update_user(attrs)
        user = @users[attrs[:id]]
        attrs.delete(:id)

        # insert updated attributes
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          user.send(setter, value) if user.class.method_defined?(setter)
        end

        user.updated_at = Time.now

        user
      end

      def delete_user(id)
        user = @users.delete(id)
        user
      end

      def get_all_users
        @users.values.sort { |a,b| a.twitter <=> b.twitter }
      end

      def destroy_all_users
        @users = {}
      end

      ###############################################
      # Audio_Blocks                                #
      ###############################################
      # songs, commercial_blocks, and commentaries  #
      # are all types of audio_blocks               #
      ###############################################
      def get_audio_block(id)
        @audio_blocks[id]
      end

      ##############
      #   Songs    #
      ##############
      def create_song(attrs)
        id = (@audio_block_counter += 1)
        attrs[:id] = id
        song = PL::Song.new(attrs)
        @audio_blocks[id] = song
        song
      end

      def get_song(id)
        @audio_blocks[id]
      end

      def update_song(attrs)
        song = @audio_blocks[attrs.delete(:id)]
        
        # return false if song doesn't exist
        return false unless song

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          song.send(setter, value) if song.class.method_defined?(setter)
        end

        song
      end

      def delete_song(id)
        song = @audio_blocks.delete(id)
        song
      end

      def song_exists?(attrs)  #title, artist, album
        songs = @audio_blocks.values.select { |song| song.is_a?(PL::Song) && 
                                              song.title.downcase == attrs[:title].downcase &&
                                              song.artist.downcase == attrs[:artist].downcase }

        if songs.size > 0
          return true
        else
          return false
        end
      end

      def get_all_songs
        all_songs = @audio_blocks.values.select { |ab| ab.is_a?(PL::Song) }.sort_by { |a| [a.artist, a.title] }
        all_songs
      end

      def get_songs_by_title(title)
        @audio_blocks.values.select { |ab| ab.is_a?(PL::Song) && 
                                      ab.title.match(/^#{title}/) }.sort_by { |x| x.title }
      end

      def get_songs_by_artist(artist)
        @audio_blocks.values.select { |ab| ab.is_a?(PL::Song) &&
                                        ab.artist.match(/^#{artist}/) }.sort_by { |x| x.title }
      end

      def get_songs_by_title_and_artist(attrs)
        songs = @audio_blocks.values.select { |song| song.is_a?(PL::Song) && 
                                              song.title.downcase == attrs[:title].downcase &&
                                              song.artist.downcase == attrs[:artist].downcase }
        songs
      end

      def get_song_by_echonest_id(echonest_id)
        @audio_blocks.values.find { |x| x.echonest_id == echonest_id }
      end


      #################
      # Commentaries  #
      #################
      def create_commentary(attrs)
        id = (@audio_block_counter += 1)
        attrs[:id] = id
        commentary = PL::Commentary.new(attrs)
        @audio_blocks[id] = commentary
        commentary
      end

      def get_commentary(id)
        @audio_blocks[id]
      end

      def update_commentary(attrs)
        commentary = @audio_blocks[attrs.delete(:id)]
        
        # return false if commentary doesn't exist
        return false unless commentary

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          commentary.send(setter, value) if commentary.class.method_defined?(setter)
        end

        commentary
      end

      def delete_commentary(id)
        deleted_commentary = @audio_blocks.delete(id)
        deleted_commentary
      end

      ####################
      # Commercials      #
      ####################
      # created with:    #
      # -------------    #
      # sponsor_id       #
      # duration (in ms) #
      # key              #
      ####################

      def create_commercial(attrs)
        id = (@audio_block_counter += 1)
        attrs[:id] = id
        commercial = Commercial.new(attrs)
        @audio_blocks[id] = commercial
        commercial
      end

      def delete_commercial(id)
        @audio_blocks.delete(id)
      end

      def get_commercial(id)
        @audio_blocks[id]
      end

      ##########################################
      #  update_commercial                     #
      #  -----------------                     #
      #  returns updated commercial object, or #
      #  FALSE if commercial not found         #
      ##########################################
      def update_commercial(attrs)
        commercial = @audio_blocks[attrs.delete(:id)]
        
        # return false if commercial doesn't exist
        return false unless commercial

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          commercial.send(setter, value) if commercial.class.method_defined?(setter)
        end

        commercial
      end

      ##################################################################
      #     commercial_blocks                                          #
      ##################################################################
      #  A commercial_block holds the commercials... it is the unit    #
      #  that enters the playlist and the only commercial unit a dj    #
      #  can change values for.                                        #
      ##################################################################
      #  values:    station_id, duration, commercials                 #
      #    NOTE: 'commercials' goes in as an array of commercial_ids   #
      #          but after input it exists as an array of commercial   #
      #          objects
      ##################################################################

      def create_commercial_block(attrs)  #duration, commercials (input:array of ids, output: array of commercial objects)
        id = (@audio_block_counter += 1)
        attrs[:id] = id
        commercial_block = CommercialBlock.new(attrs)
        @audio_blocks[id] = commercial_block
        commercial_block
      end

      def get_commercial_block(id)
        @audio_blocks[id]
      end

      def get_commercial_block_by_current_position(attrs)
        @audio_blocks.values.find { |commercial_block| commercial_block.is_a?(PL::CommercialBlock) && 
                                      commercial_block.station_id == attrs[:station_id] && 
                                      commercial_block.current_position = attrs[:current_position] }
      end 
      

      ###########################################
      #  update_commercial_block                #
      #  -----------------                      #
      #  returns updated commercial_block       #           
      #  object, or FALSE if block is not found #
      ###########################################
      def update_commercial_block(attrs)
        commercial_block = @audio_blocks[attrs.delete(:id)]
        
        # return false if commercial_block doesn't exist
        return false unless commercial_block

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          commercial_block.send(setter, value) if commercial_block.class.method_defined?(setter)
        end

        commercial_block
      end

      def delete_commercial_block(id)
        @audio_blocks.delete(id)
      end


      ##############
      #  Stations  #
      ##############
      def create_station(attrs)
        id = (@station_id_counter += 1)
        attrs[:id] = id
        station = Station.new(attrs)
        @stations[id] = station
        station
      end

      def get_station(id)
        @stations[id]
      end

      def update_station(attrs)
        station = @stations[attrs.delete(:id)]
        
        # return false if station doesn't exist
        return false if station.nil?

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          station.send(setter, value) if station.class.method_defined?(setter)
        end

        station
      end

      def get_station_by_uid(user_id)
        @stations.values.find { |station| station.user_id == user_id }
      end

      def destroy_all_stations
        @stations = {}
      end

      def get_all_stations
        @stations.values
      end

      ##################################################################
      #     spin_frequency                                             #
      ##################################################################
      #  A spin_frequency stores the number of times a song should     #
      #  be played in 1 week on the station.    (spins_per_week)       #
      ##################################################################
      #  values:    song_id, station_id, spins_per_week (Integer)      #
      ##################################################################
      def create_spin_frequency(attrs)
        station = self.get_station(attrs[:station_id])
        station.spins_per_week[attrs[:song_id]] = attrs[:spins_per_week]
        station
      end

      def delete_spin_frequency(attrs)
        station = self.get_station(attrs[:station_id])

        station.spins_per_week[attrs[:song_id]] = nil

        station
      end

      def destroy_all_spin_frequencies
        @stations.values.each { |station| station.spins_per_week = {} }
      end

      ########################
      #        spins         #
      # -------------------  #
      # station_id          #
      # current_position     #
      # audio_block_id       #
      # airtime    #
      # duration             #
      ########################
      def create_spin(attrs)
        id = (@spin_counter += 1)
        attrs[:id] = id
        spin = Spin.new(attrs)
        @spins[spin.id] = spin
        spin
      end

      def get_spin(id)
        @spins[id]
      end

      ################################################
      # delete_spin just deletes the spin, whereas   #
      # remove_spin pulls it out of the playlist and #
      # adjusts the rest of the playlist accordingly #
      ################################################
      def delete_spin(id)
        deleted_spin = @spins.delete(id)
        deleted_spin
      end

      def update_spin(attrs)
        spin = @spins[attrs[:id]]

        # return false if spin doesn't exist
        return false unless spin

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          spin.send(setter, value) if spin.class.method_defined?(setter)
        end

        spin
      end

      def delete_spins_for_station(station_id)
        @spins.delete_if { |spin_id| self.get_spin(spin_id).station_id == station_id }
      end


      def get_final_spin(station_id)
        @spins.values.select { |spin| spin.station_id == station_id }.max_by { |spin| spin.current_position }
      end

      def mass_add_spins(spins)
        spins.each do |spin|
          self.create_spin({ station_id: spin.station_id,
                              audio_block_id: spin.audio_block_id,
                              current_position: spin.current_position,
                              airtime: spin.airtime,
                              created_at: Time.now,
                              updated_at: Time.now })
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
        playlist = self.get_full_playlist(attrs[:station_id])
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

      ################################################################
      #                        insert_spin                           #
      ################################################################
      # insert_spin inserts a spin into the playlist.                #
      # it also deletes the 1st song after 3am (or 2am the following #
      # day) to counterbalance the inserted song                     #
      #  ----------------------------------------------------------- #
      # takes: station_id, insert_position, audio_block_id          #
      ################################################################
      def insert_spin(attrs)
        station = self.get_station(attrs[:station_id])
        station.update_airtimes
        playlist = self.get_full_playlist(station.station_id)
        index = playlist.find_index { |spin| spin.current_position == attrs[:insert_position] }
        current_position_tracker = attrs[:insert_position]

        # if insert happens in the 3am hour, set marker to the following 1am
        if playlist[index].airtime.hour == 3
          change_hour = 2
        else
          change_hour = 3
        end

        # adjust current_position until change_hour
        while (playlist[index].airtime.hour != change_hour) && (index < playlist.size)
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

      def get_full_playlist(station_id)
        spins = @spins.values.select { |spin| spin.station_id == station_id }
        spins = spins.sort_by { |spin| spin.current_position }
      end

      def get_partial_playlist(attrs)
        case
        when !attrs[:start_time]
          spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                                  (spin.airtime <= attrs[:end_time]) }
        when !attrs[:end_time]
          spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                                (spin.airtime >= attrs[:start_time]) }
        else
          spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                              (spin.airtime >= attrs[:start_time]) &&
                                              (spin.airtime <= attrs[:end_time]) }
        spins = spins.sort_by { |spin| spin.current_position }
        spins
        end
      end

      def playlist_exists?(station_id)
        if @spins.values.find { |spin| spin.station_id == station_id }
          return true
        else
          return false
        end
      end

      def get_playlist_by_current_positions(attrs)
        if !attrs[:ending_current_position]
          spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                                (spin.current_position >= attrs[:starting_current_position]) }
        else
          spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                                (spin.current_position >= attrs[:starting_current_position]) &&
                                                (spin.current_position <= attrs[:ending_current_position]) }
        end
        
        spins = spins.sort_by { |spin| spin.current_position }
        spins
      end

      def get_spin_by_current_position(attrs)
        spin = @spins.values.find { |spin| (spin.station_id == attrs[:station_id]) && 
                                    (spin.current_position == attrs[:current_position]) }
        spin
      end

      def get_last_spin(station_id)
        spin = @spins.values.select { |spin| (spin.station_id == station_id) }.max_by { |spin| spin.current_position }
        spin
      end

      def get_next_spin(station_id)
        spin = @spins.values.select { |spin| (spin.station_id == station_id) }.min_by { |spin| spin.current_position }
        spin
      end

      def get_spin_after_next(station_id)
        next_spin = self.get_next_spin(station_id)
        spin_after_next = self.get_spin_by_current_position({ station_id: station_id,
                                                              current_position: next_spin.current_position + 1 })
        spin_after_next
      end

      ####################################
      # move_spin                        #
      # -------------------------------- #
      # takes old_position, new_position #
      # returns true for success, false  #
      # for failure                      #
      ####################################
      def move_spin(attrs)   #old_position, new_position, station_id
        #if moving backwards
        if attrs[:old_position] > attrs[:new_position]
          playlist_slice = self.get_full_playlist(attrs[:station_id]).select { |spin| (spin.current_position >= attrs[:new_position]) && (spin.current_position <= attrs[:old_position]) }

          playlist_slice.each { |spin| spin.current_position += 1 }

          playlist_slice.last.current_position = attrs[:new_position]

          # return true for successful move
          return true
        elsif attrs[:old_position] < attrs[:new_position]
          playlist_slice = self.get_full_playlist(attrs[:station_id]).select { |spin| (spin.current_position >= attrs[:old_position]) && (spin.current_position <= attrs[:new_position]) }

          playlist_slice.each { |spin| spin.current_position -= 1 }

          playlist_slice.first.current_position = attrs[:new_position]

          # return true for successful move
          return true
        end

        # return false if nothing was moved
        return false
      end

      def destroy_all_spins
        @spin_counter = 700
        @spins = {}
      end

      ########################
      #       log_entries    #
      #      ------------    #
      # station_id           #
      # current_position     #
      # audio_block_id       #
      # airtime              #
      # duration             #
      # listeners_at_start   #
      # listeners_at_finish  #
      ########################
      def create_log_entry(attrs)
        id = (@log_entry_counter += 1)
        attrs[:id] = id
        log_entry = PL::LogEntry.new(attrs)
        @log_entries[id] = log_entry
        log_entry
      end

      def get_recent_log_entries(attrs)  #station_id, count (how many entries to return)
        entries = @log_entries.values.select { |entry| entry.station_id == attrs[:station_id]}
        entries = entries.sort_by { |entry| entry.airtime }
        entries = entries.last(attrs[:count]).reverse
        entries
      end

      def get_full_station_log(station_id)
        entries = @log_entries.values.select { |entry| entry.station_id == station_id }
        entries = entries.sort_by { |entry| entry.airtime}.reverse
        entries
      end

      def get_log_entry(id)
        @log_entries[id]
      end

      def update_log_entry(attrs)
        entry = @log_entries[attrs[:id]]

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          entry.send(setter, value) if entry.class.method_defined?(setter)
        end
        entry
      end

      def destroy_all_log_entries
        @log_entry_counter = 800
        @log_entries = {}
      end

      def log_exists?(station_id)
        if  @log_entries.values.find { |entry| entry.station_id == station_id }
          return true
        else
          return false
        end
      end

      def get_log_entry_by_current_position(attrs)
        result = @log_entries.values.select { |entry| entry.station_id == attrs[:station_id] &&
                                              entry.current_position == attrs[:current_position] &&
                                              !entry.audio_block.is_a?(PL::CommercialBlock) }

        if result.size
          return result[0]
        else
          return nil
        end
      end

      def get_log_entries_by_date_range(attrs)
        # if not end_date is included, use only that day
        if !attrs[:end_date] then (attrs[:end_date] = attrs[:start_date]) end

        start_datetime = attrs[:start_date].to_time
        end_datetime = (attrs[:end_date] + 1).to_time  # +1 for the next midnight 

        entries = @log_entries.values.select { |entry| entry.station_id == attrs[:station_id] &&
                                              entry.airtime > start_datetime &&
                                              entry.airtime < end_datetime }.sort_by { |entry| entry.airtime }
        entries
      end

      ##############
      #  Sessions  #
      ##############

      def create_session(user_id)
        session_id = SecureRandom.uuid
        @sessions[session_id] = user_id
        return session_id
      end

      def get_uid_by_sid(session_id)
        @sessions[session_id]
      end

      def get_sid_by_uid(user_id)
        if @sessions.has_value?(user_id)
          return @sessions.find { |k,v| v == user_id }[0]
        else
          return nil
        end
      end

      def delete_session(session_id)
        if @sessions[session_id]
          @sessions.delete(session_id)
          return true
        else
          return false
        end
      end

      #####################
      #  Twitter Friends  #
      #####################
      def store_twitter_friends(attrs)
        @twitter_friends[attrs[:follower_uid]] = attrs[:followed_station_ids]
      end

      def get_followed_stations_list(id)
        if !@twitter_friends[id]
          return []
        else
          return @twitter_friends[id].sort
        end
      end

      ######################
      #  Listening Session #
      ######################
      def create_listening_session(attrs)
        id = (@listening_session_counter += 1)
        attrs[:id] = id
        listening_session = PL::ListeningSession.new(attrs)
        @listening_sessions[id] = listening_session
        listening_session
      end

      def update_listening_session(attrs)
        listening_session = @listening_sessions[attrs[:id]]

        #update values
        attrs.each do |attr_name, value|
          setter = "#{attr_name}="
          listening_session.send(setter, value) if listening_session.class.method_defined?(setter)
        end
        listening_session
      end

      def delete_listening_session(id)
        @listening_sessions[id] = nil
      end

      def get_listening_session(id)
        @listening_sessions[id]
      end

      #############################################
      #   find_listening_session                  #
      #############################################
      #  takes user_id, station_id, end_time      #
      #############################################
      #  returns array of listening_sessions for  #
      #      all that end within 2 min of request #
      #############################################
      def find_listening_session(attrs)
        listening_session = @listening_sessions.values.select { |session| (session.station_id == attrs[:station_id]) &&
                                                      ((session.end_time - attrs[:end_time]).abs <= (60*2) || (session.end_time > attrs[:end_time])) &&   # 2 min window each side
                                                      (session.user_id === attrs[:user_id]) }.first

        listening_session
      end

      def get_listener_count(attrs)
        if !attrs[:time]
          attrs[:time] = Time.now
        end

        count = @listening_sessions.values.select { |session| (session.station_id == attrs[:station_id]) && 
                                                               (session.end_time >= attrs[:time]) &&
                                                               (session.start_time <= attrs[:time]) }.size
        count
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
            id = (@genre_id_counter += 1)
            @genres[id] = { song_id: attrs[:song_id], genre: genre }
          end
        end
      end

      def get_genres(song_id)
        genres = @genres.values.select { |genre_record| genre_record[:song_id] == song_id }
        if genres.size == 0
          return []
        else
          return genres.map { |genre_record| genre_record[:genre] }.sort
        end
      end

      def delete_genres(attrs)
        attrs[:genres].each do |genre|
          @genres.delete_if { |k,v| (v[:genre] == genre) &&
                                              (v[:song_id] == attrs[:song_id]) }
        end
        return self.get_genres(attrs[:song_id])
      end

      def destroy_all_genres
        @genres = {} 
      end
    end
  end
end