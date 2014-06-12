require 'zlib'

module PL
  module Database

    # def self.db
    #   @__db_instance ||= InMemory.new
    # end

    class InMemory

      def initialize(env=nil)
        clear_everything
      end

      def clear_everything
      	@user_id_counter = 100
      	@users = {}
        @song_id_counter = 200
        @songs = {}
        @station_id_counter = 300
        @stations = {}
        @commentary_id_counter = 400
        @commentaries = {}
        @commercial_block_counter = 500
        @commercial_blocks = {}
        @commercial_counter = 600
        @commercials = {}
        @spin_counter = 700
        @spins = {}


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

      ##############
      #   Songs    #
      ##############
      def create_song(attrs)
        id = (@song_id_counter += 1)
        attrs[:id] = id
        song = PL::Song.new(attrs)
        @songs[id] = song
        song
      end

      def get_song(id)
        @songs[id]
      end

      def update_song(attrs)
        song = @songs[attrs.delete(:id)]
        
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
        song = @songs.delete(id)
        song
      end

      def song_exists?(attrs)  #title, artist, album
        songs = @songs.values.select { |song| song.title == attrs[:title] &&
                                              song.album == attrs[:album] &&
                                              song.artist == attrs[:artist] }

        if songs.size > 0
          return true
        else
          return false
        end
      end

      def get_all_songs
        all_songs = @songs.values.sort_by { |a| [a.artist, a.title] }
        all_songs
      end

      def get_songs_by_title(title)
        @songs.values.select { |song| song.title.match(/^#{title}/) }.sort_by { |x| x.title }
      end

      def get_songs_by_artist(artist)
        @songs.values.select { |song| song.artist.match(/^#{artist}/) }.sort_by { |x| x.title }
      end


      #################
      #  Commentaries #
      #################
      def create_commentary(attrs)
        id = (@commentary_id_counter += 1)
        attrs[:id] = id
        commentary = PL::Commentary.new(attrs)
        @commentaries[id] = commentary
        commentary
      end

      def get_commentary(id)
        @commentaries[id]
      end

      def update_commentary(attrs)
        commentary = @commentaries[attrs.delete(:id)]
        
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
        deleted_commentary = @commentaries.delete(id)
        deleted_commentary
      end

      #################
      # Commercials   #
      #################
      # created with: #
      # ------------- #
      # sponsor_id    #
      # duration      #
      # key           #
      #################
      def create_commercial(attrs)
        id = (@commercial_counter += 1)
        attrs[:id] = id
        commercial = Commercial.new(attrs)
        @commercials[id] = commercial
        commercial
      end

      def delete_commercial(id)
        @commercials.delete(id)
      end

      def get_commercial(id)
        @commercials[id]
      end

      ##########################################
      #  update_commercial                     #
      #  -----------------                     #
      #  returns updated commercial object, or #
      #  FALSE if commercial not found         #
      ##########################################
      def update_commercial(attrs)
        commercial = @commercials[attrs.delete(:id)]
        
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
        id = (@commercial_block_counter += 1)
        attrs[:id] = id
        commercial_block = CommercialBlock.new(attrs)
        @commercial_blocks[id] = commercial_block
        commercial_block
      end

      def get_commercial_block(id)
        @commercial_blocks[id]
      end
      

      ###########################################
      #  update_commercial_block                #
      #  -----------------                      #
      #  returns updated commercial_block       #           
      #  object, or FALSE if block is not found #
      ###########################################
      def update_commercial_block(attrs)
        commercial_block = @commercial_blocks[attrs.delete(:id)]
        
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
        @commercial_blocks.delete(id)
      end


      ##############
      #  Stations  #
      ##############
      def create_station(attrs)
        id = (@station_id_counter += 1)
        attrs[:id] = id

        heavy = attrs.delete(:heavy)
        medium = attrs.delete(:medium)
        light = attrs.delete(:light)

        heavy ||= {}
        medium ||= {}
        light ||= {}

        station = Station.new(attrs)

        heavy.each { |rotation| station.spins_per_week[rotation] = PL::HEAVY_ROTATION }
        medium.each { |rotation| station.spins_per_week[rotation] = PL::MEDIUM_ROTATION }
        light.each { |rotation| station.spins_per_week[rotation] = PL::LIGHT_ROTATION }

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

      def update_spin_frequency(attrs)
        station = self.get_station(attrs[:station_id])

        if attrs[:spins_per_week] == 0
          station.spins_per_week[attrs[:song_id]] = nil
        else
          station.spins_per_week[attrs[:song_id]] = attrs[:spins_per_week]
        end
        station
      end

      ########################
      #        spins         #
      # -------------------  #
      # current_position     #
      # audio_block_type     # 
      # audio_block_id       #
      # estimated_air_time   #
      # duration             #
      ########################
      def schedule_spin(attrs)
        id = (@spin_counter += 1)
        attrs[:id] = id
        spin = Spin.new(attrs)
        @spins[spin.id] = spin
        spin
      end

      def delete_spin(attrs)
      end

      def insert_spin(attrs)
      end

      def get_current_playlist(station_id)
        spins = @spins.values.select { |spin| spin.station_id == station_id }
        spins.select { |spin| spin.played_at == nil }.sort_by { |x| x.current_position }
      end

      ####################################
      # move_spin                        #
      # -------------------------------- #
      # takes old_position, new_position #
      # returns true for success, false  #
      # for failure                      #
      ####################################
      def move_spin(attrs)
      end

  	end
  end
end