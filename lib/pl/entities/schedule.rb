module PL
  class Schedule
  
    attr_accessor :id, :station, :current_playlist_end_time,
    attr_accessor :original_playlist_end_time, :next_commercial_block,
    attr_accessor :last_accurate_airtime

    # constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400

    def generate_playlist
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)

      # set max_position and time_tracker initial values
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
      end

      # calibrate commercial_time_block_counter for start-time
      commercial_time_block_counter = commercial_time_block(time_tracker)

      sample_array = 
    end
    

    def bring_schedule_current
    end

    # returns the 'block' number for the given time
    def commercial_time_block(time)
      (time.to_f/1800.0).floor
    end
  
  end
end