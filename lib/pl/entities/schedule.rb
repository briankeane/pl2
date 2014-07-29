require 'chronic'
require 'tempfile'
require 'active_support'
require 'timezone'

module PL
  class Schedule < Entity
  
    attr_accessor :id, :station_id, :current_playlist_end_time
    attr_accessor :original_playlist_end_time, :next_commercial_block
    attr_accessor :last_accurate_current_position, :next_commercial_block_id

    # constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400
    SPINS_WITHOUT_REPEAT = 35

    def initialize(attrs)
      super(attrs)
      Time.zone = timezone || 'Central Time (US & Canada)'
    end

    def timezone
      if !station
        'Central Time (US & Canada)'
      else
        station.timezone
      end
    end

    def station
      @station ||= PL.db.get_station(@station_id)
    end

    def generate_playlist(end_time=nil)
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)
      
      # keep end_time within range
      if end_time
        end_time = [end_time, next_thursday_midnight].min
      else
        end_time = next_thursday_midnight
      end

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

      sample_array = station.create_sample_array

      recently_played = []
      spins = []

      while time_tracker < end_time

        # insert time for a commercial if it's time
        if find_commercial_count(time_tracker) > commercial_counter
          time_tracker += @station.secs_of_commercial_per_hour/2
          commercial_counter += 1
        end

        song = sample_array.sample

        # pick again until it hasn't been played recently
        while recently_played.include?(song)
          song = sample_array.sample
        end

        recently_played << song

        # if the recently_played is at max size, delete the first song
        if ((recently_played.size >= SPINS_WITHOUT_REPEAT) ||
              (recently_played.size >= station.spins_per_week.size - 1))
          recently_played.shift
        end

        spin =  Spin.new({ schedule_id: @id,
                            audio_block_id: song.id,
                            current_position: (max_position += 1),
                            estimated_airtime: time_tracker })
        spins << spin
        
        time_tracker += (spin.duration/1000)

      end #end while

      PL.db.mass_add_spins(spins)

      
      @original_playlist_end_time = time_tracker
      @last_accurate_current_position = spins.last.current_position
      @current_playlist_end_time = time_tracker

      #if it's the first playlist, start the station
      if PL.db.get_recent_log_entries({ station_id: @station_id, count: 1 }).size == 0
        first_spin = PL.db.get_next_spin(@id)
        PL.db.create_log_entry({ station_id: @station_id,
                                 current_position: first_spin.current_position,
                                 audio_block_id: first_spin.audio_block_id,
                                 airtime: first_spin.estimated_airtime,
                                 duration: first_spin.duration
                                 })
        PL.db.delete_spin(first_spin.id)
      end
    end

    def bring_current
      # if the station is already active, do nothing
      if station.active?
        return
      end

      # finish the current_spin
      last_played = PL.db.get_recent_log_entries({ station_id: @station_id, count: 1}).first
      last_played = PL.db.update_log_entry({ id: last_played.id,
                                            listeners_at_finish: 0 })
      time_tracker = last_played.airtime + (last_played.duration/1000)

      playlist = PL.db.get_full_playlist(@id)       
     
      playlist.each_with_index do |spin, i|
        break unless (time_tracker < Time.now)

        

        # set up listeners_at_finish to put nil in the final spin
        if (time_tracker + spin.duration/1000) > Time.now
          listeners_at_finish = nil
        else
          listeners_at_finish = 0
        end

        log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                              current_position: spin.current_position,
                                              audio_block_id: spin.audio_block_id,
                                              airtime: time_tracker,
                                              duration: spin.duration,
                                              listeners_at_start: 0,
                                              listeners_at_finish: listeners_at_finish })
        spin.estimated_airtime = time_tracker
        time_tracker += spin.duration/1000
      end
    end

    def update_estimated_airtimes(endtime = nil)
      if last_accurate_airtime < Time.now
        self.bring_current
        last_played = PL.db.get_recent_log_entries({ station_id: @station_id, count: 1 }).first
        start_time = last_played.airtime + last_played.duration/1000
        if find_commercial_count(last_played.airtime) != find_commercial_count(start_time)
          lead_with_commercial = true
        end
        playlist = PL.db.get_full_playlist(@id)
      else
        PL.db.
      time_tracker = station.log_end_time
      end
    end

    # returns the 'block' number for the given time
    def find_commercial_count(time)
      (time.to_f/1800.0).floor
    end

    #######################################################
    #  adjust_playlist                                    #
    #######################################################
    # takes an array of spins and a start time, returns   #
    # correct time with commercials                       #
    #######################################################
    # options: insert_commercials?                        #
    #          -- if true, inserts cb's into the array    #
    #             false, just accounts for their time     #
    #          lead_with_commercial_block?                #
    #             -- if true starts w/ commercial block   #
    #######################################################
    def adjust_playlist(attrs)

      max_position = attrs[:playlist].last.current_position
      time_tracker = attrs[:start_time]

      # calibrate commercial_counter for start_time
      commercial_counter = find_commercial_count(time_tracker)

      # adjust if it should start with a commercial
      if attrs[:lead_with_commercial_block?]
        commercial_counter -= 1
      end

      modified_playlist = []

      attrs[:playlist].each do |spin|
        # if it's time for a commercial
        if commercial_counter != find_commercial_count(time_tracker)
          commercial_counter += 1

          if attrs[:insert_commercials?]
            modified_playlist << PL::CommercialBlock.new(
                                        { schedule_id: spin.schedule_id,
                                          estimated_airtime: time_tracker,
                                          duration: @station.secs_of_commercial_per_hour/2 })
          end
          
          time_tracker += @station.secs_of_commercial_per_hour/2
        end

        spin.estimated_airtime = time_tracker
        modified_playlist << spin

        time_tracker += spin.duration/1000
      end

      modified_playlist
    end

    def last_accurate_airtime
      spin = PL.db.get_spin_by_current_position({ schedule_id: @id, current_position: @last_accurate_current_position })
      if spin
        airtime = spin[:estimated_airtime]
      else
        # set to a valid minimum value
        airtime = Time.local(1970,1,1)
      end
      airtime
    end
  end
end