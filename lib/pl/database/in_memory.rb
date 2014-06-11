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
      end
  	end
  end
end