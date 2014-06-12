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

      #####################
      # Commercial_Blocks #
      #####################
      def create_commercial_block(attrs)
        id = (@commercial_block_counter += 1)
        attrs[:id] = id
        commercial_block = CommercialBlock.new(attrs)
        @commercial_blocks[id] = commercial_block
        commercial_block
      end

      def get_commercial_block(id)
        @commercial_blocks[id]
      end

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
      #  returns:   updated version of the station                     #
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


  	end
  end
end