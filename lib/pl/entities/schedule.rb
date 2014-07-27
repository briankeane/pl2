require 'chronic'
require 'tempfile'
require 'active_support'

module PL
  class Schedule < Entity
  
    attr_accessor :id, :station_id, :current_playlist_end_time
    attr_accessor :original_playlist_end_time, :next_commercial_block
    attr_accessor :last_accurate_airtime, :next_commercial_block_id

    # constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400
    SPINS_WITHOUT_REPEAT = 35

    def initialize(attrs)
      super(attrs)
      Time.zone = station.timezone unless !station
    end

    def station
      @station ||= PL.db.get_station(@station_id)
    end



    def generate_playlist(end_time)
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)
      
      # keep end_time within range
      end_time = [end_time, next_thursday_midnight].min unless !end_time

      # set max_position and time_tracker initial values
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.zone.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
      end

      # calibrate commercial_counter for start-time
      commercial_counter = find_commercial_count(time_tracker)

      sample_array = @station.create_sample_array

      recently_played = []
      spins = []

      while time_tracker < end_time

        # insert time for a commercial if it's time
        if find_commercial_count(time_tracker) > commercial_counter
          time_tracker += @station.secs_of_commercial_per_hour
          commercial_block_counter += 1
        end

        song = sample_array.song

        # pick again until it hasn't been played recently
        while recently_played.include?(song)
          song = sample_array.sample
        end

        recently_played << song

        # if the recently_played is at max size, delete the first song
        if ((recently_played.size >= SPINS_WITHOUT_REPEAT) ||
              (recently_played.size >= @spins_per_week.size - 1))
          recently_played.shift
        end

        spin =  Spin.new({ station_id: @station.id,
                            audio_block_id: song.id,
                            current_position: (max_position += 1),
                            estimated_airtime: time_tracker })
        spins << spin
        
        time_tracker += (spin.duration/1000)

      end #end while

      PL.db.mass_add_spins(spins)

      
      @original_playlist_end_time = time_tracker
      @last_accurate_airtime = time_tracker
      @current_playlist_end_time = time_tracker
    end


    def bring_schedule_current
    end

    # returns the 'block' number for the given time
    def find_commercial_count(time)
      (time.to_f/1800.0).floor
    end
    
  end
end