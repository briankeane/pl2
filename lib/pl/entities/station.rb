require 'chronic'

module PL
	class Station < Entity
		attr_accessor :id, :secs_of_commercial_per_hour, :user_id
		attr_accessor	:spins_per_week, :created_at, :updated_at
		attr_accessor :current_playlist_end_time, :original_playlist_end_time

		# Station-specific constants
		MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400

		def initialize(attrs)
 
			heavy = attrs.delete(:heavy)
			medium = attrs.delete(:medium)
			light = attrs.delete(:light)

			heavy ||= {}
			medium ||= {}
			light ||= {}

			#store spins_per_week
			@spins_per_week = {}
			heavy.each do |song_id|
				@spins_per_week[song_id] = PL::HEAVY_ROTATION
			end

			medium.each do |song_id|
				@spins_per_week[song_id] = PL::MEDIUM_ROTATION
			end

			light.each do |song_id|
				@spins_per_week[song_id] = PL::LIGHT_ROTATION
			end

			attrs[:secs_of_commercial_per_hour] ||= PL::DEFAULT_SECS_OF_COMMERCIAL_PER_HOUR
			
			super(attrs)
		end

		##################################################################
    #     create_sample_array                                        #
    ##################################################################
    #  This method creates an array of samples for the playlist      #
    #  generator to randomly select from.  It populates each song    #
    #  in the correct ratio. 																				 #
    #  The values are stored in the array as song objects (not ids)  #
    ##################################################################

    def create_sample_array
      sample_array = []

      # add songs to sample-array in correct ratios
     	@spins_per_week.each do |k,v|
     		v.times { sample_array << PL::db.get_song(k) }
     	end

      sample_array
    end

    ##################################################################
    #     generate_playlist                                          #
    ##################################################################
    #  This method generates or extends the current playlist         #
    #  through the following thursday at midnight.  It takes         #
    #  commercial time into account but does not insert commercial   #
    #  blocks or placeholders.  Currently it gets the ratios correct #
    #  but later it should be ammended to account for:               #
    #                                                                #
    #     1) no repeats (spacing between same artist/song)           #
    #     2) station ids                                             #
    ##################################################################

    def generate_playlist
      # set up beginning and ending dates for comparison
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_current_playlist(@id)
      time_tracker = nil

      # set max_position and time_tracker initial values
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.now
      else
        max_position = current_playlist.last.current_position
        current_spin = PL.db.get_current_spin(@id)
        time_tracker = self.playlist_estimated_end_time
      end

      # calibrate commercial_block_counter for start-time
      commercial_block_counter = (time_tracker.to_f/1800.0).floor

      sample_array = self.create_sample_array

      recently_played = []

      while time_tracker < next_thursday_midnight
        #if it's time for a commercial, move time-tracker over it's block

        if (time_tracker.to_f/1800.0).floor > commercial_block_counter
          commercial_block_counter += 1
          time_tracker += (@secs_of_commercial_per_hour/2)
        end

        song = sample_array.sample

        # IF it's been played recently, pick a new song
				while recently_played.include?(song)
					song = sample_array.sample
				end

				# Push the new song to the recently_played array
				recently_played << song

				# If the array is at max size, delete the first song
				if ((recently_played.size >= PL::SPINS_WITHOUT_REPEAT) ||
								(recently_played.size >= @spins_per_week.size - 1))
					recently_played.shift
				end


        spin = PL.db.schedule_spin({ station_id: @id,
        														 audio_block_type: 'song',
                                     audio_block_id: song.id,
                                     current_position: (max_position += 1),
                                     estimated_airtime: time_tracker })

        time_tracker += (song.duration/1000)

      end  # endwhile

      #if it's the first playlist, start the station
      if PL.db.get_recent_log_entries({ station_id: @id, count: 1 }).size == 0
        first_spin = PL.db.get_current_playlist(@id).first
        PL.db.create_log_entry({ station_id: @id,
        												 current_position: first_spin.current_position,
        												 audio_block_type: 'song',
        												 audio_block_id: song.id,
        												 airtime: first_spin.estimated_airtime
        												 })
        PL.db.delete_spin(first_spin.id)
      end
    end
	end
end
