require 'zlib'

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
                                              song.album.downcase == attrs[:album].downcase &&
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
      #  values:    station_id, duration, commercials                  #
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

      def get_station_by_user_id(user_id)
        @stations.values.find { |station| station.user_id == user_id }
      end

      ##################################################################
      #     spin_frequency                                             #
      ##################################################################
      #  A spin_frequency stores the number of times a song should     #
      #  be played in 1 week on the station.    (spins_per_week)       #
      ##################################################################
      #  values:    song_id, station_id, spins_per_week (Integer)      #
      ##################################################################
      def record_spin_frequency(attrs)
        station = self.get_station(attrs[:station_id])
        station.spins_per_week[attrs[:song_id]] = attrs[:spins_per_week]
        station
      end

      def delete_spin_frequency(attrs)
        station = self.get_station(attrs[:station_id])

        station.spins_per_week[attrs[:song_id]] = nil

        station
      end

      ########################
      #        spins         #
      # -------------------  #
      # station_id           #
      # current_position     #
      # audio_block_id       #
      # estimated_airtime    #
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
        spins = @spins.values.select { |spin| (spin.station_id == attrs[:station_id]) &&
                                              (spin.estimated_airtime >= attrs[:start_time]) &&
                                              (spin.estimated_airtime <= attrs[:end_time]) }
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
        entries = entries.sort_by { |entry| entry.current_position }
        entries = entries.last(attrs[:count]).reverse
        entries
      end

      def get_full_station_log(station_id)
        entries = @log_entries.values.select { |entry| entry.station_id == station_id }
        entries = entries.sort_by { |entry| entry.current_position}.reverse
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

    end
  end
end