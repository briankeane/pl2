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

    def playlist_exists?
      PL.db.playlist_exists?(@id)
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

    def generate_playlist(playlist_end_time=nil)
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)
      
      self.update_estimated_airtimes

      # exit if playlist is already maxxed out
      if self.end_time
        if self.end_time > next_thursday_midnight
          return
        end
      end

      # keep end_time within range
      if playlist_end_time
        playlist_end_time = [playlist_end_time, next_thursday_midnight].min
      else
        playlist_end_time = next_thursday_midnight
      end


      # set max_position and time_tracker initial values

      commercial_leads_in = false
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.zone.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
        if find_commercial_count(current_playlist.last.current_position) != find_commercial_count(self.end_time)
          commercial_leads_in = true
        end
      end

      # calibrate commercial_counter for start-time
      commercial_counter = find_commercial_count(time_tracker)

      # adjust if first spin should be a commercial
      if commercial_leads_in == true
        commercial_counter = commercial_counter - 1
      end

      sample_array = station.create_sample_array

      recently_played = []
      spins = []


      while time_tracker < playlist_end_time

        # insert time for a commercial if it's time
        if find_commercial_count(time_tracker) > commercial_counter
          time_tracker += @station.secs_of_commercial_per_hour/2
          commercial_counter += 1
          commercial_leads_in = true
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
                            estimated_airtime: time_tracker,
                            commercial_leads_in: commercial_leads_in })
        spins << spin
        
        time_tracker += (spin.duration/1000)
        commercial_leads_in = false

      end #end while

      PL.db.mass_add_spins(spins)

      @original_playlist_end_time = time_tracker
      @last_accurate_current_position = spins.last.current_position
      PL.db.update_schedule({ id: @id, last_accurate_current_position: @last_accurate_current_position })
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

    def end_time
      self.update_estimated_airtimes
      last_spin = PL.db.get_last_spin(@id)
      if !last_spin
        return nil
      else
        return last_spin.estimated_end_time
      end
    end

    def active?
      # if there's no station...
      if !station || !station.log_end_time
        return nil
      else
        return (station.log_end_time.utc < Time.now.utc) ? false : true
      end
    end

                 
    def update_estimated_airtimes(endtime = nil)
      # if there's no playlist yet, just exit
      if !playlist_exists?
        return false
      end

      # exit if an endtime is provided and it's already accurate
      if endtime && (endtime < last_accurate_airtime)
        return false
      end

      # if the last_accurate_current_position is after the log, use it as the starting point
      if last_accurate_current_position > station.just_played.current_position
        playlist = PL.db.get_playlist_by_starting_current_position({ schedule_id: @id,
                                                                     starting_current_position: @last_accurate_current_position })
        
        time_tracker = playlist[0].estimated_airtime
        if playlist[0].commercial_leads_in
          leading_commercial = true

          # counteract the commercial-padding for the 1st iteration
          time_tracker -= station.secs_of_commercial_per_hour/2
        end

      else  # otherwise use the log as the starting point
        playlist = PL.db.get_full_playlist(@id)
        time_tracker = station.just_played.estimated_end_time
        if find_commercial_count(station.just_played.airtime) != find_commercial_count(station.just_played.estimated_end_time)
          leading_commercial = true
        else
          leading_commercial = false
        end
      end

      # calibrate commercial counter
      commercial_counter = find_commercial_count(time_tracker)
      if leading_commercial
        commercial_counter -= 1
      end

      # update the database
      playlist.each do |spin|
        if find_commercial_count(time_tracker) != commercial_counter
          leading_commercial = true
          time_tracker += station.secs_of_commercial_per_hour/2
          commercial_counter += 1
        end

        PL.db.update_spin({ id: spin.id,
                            commercial_leads_in: leading_commercial,
                            estimated_airtime: time_tracker })
        @last_accurate_current_position = spin.current_position
        PL.db.update_schedule({ id: @id, last_accurate_current_position: @last_accurate_current_position })

        leading_commercial = false
        time_tracker += spin.duration/1000

        # break out if job finishes early
        if endtime
          if spin.estimated_airtime > endtime
            break
          end
        end
      end

      # write new last_accurate_current_position to database
      PL.db.update_schedule({ id: @id, last_accurate_current_position: @last_accurate_current_position })
    end

    # returns the 'block' number for the given time
    def find_commercial_count(time)
      (time.to_f/1800.0).floor
    end

    def bring_current
      # if the station is already active or no playlist has been created, yet, do nothing
      if station.active? || !playlist_exists?
        return
      end
      
      self.update_estimated_airtimes(Time.now)

      playlist = PL.db.get_partial_playlist({ schedule_id: @id, end_time: Time.now })

      # mark the last-started song as finished
      unfinished_log = PL.db.get_recent_log_entries({ station_id: @station_id, count: 1 })[0]
      PL.db.update_log_entry({ id: unfinished_log.id,
                              listeners_at_finish: 0 })

      log_entry = nil
      playlist.each do |spin|
        if spin.commercial_leads_in
          log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                              audio_block_id: station.next_commercial_block.id,
                                              airtime: (spin.estimated_airtime - station.secs_of_commercial_per_hour/2),
                                              listeners_at_start: 0,
                                              listeners_at_finish: 0,
                                              duration: (station.secs_of_commercial_per_hour/2 * 1000)
                                            })
          station.advance_commercial_block
        end

        # break out if the commercial is the current spin
        if spin.estimated_airtime > Time.now
          break
        end


        log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                    listeners_at_start: 0,
                                    listeners_at_finish: 0,
                                    audio_block_id: spin.audio_block_id,
                                    duration: spin.duration,
                                    airtime: spin.estimated_airtime,
                                    current_position: spin.current_position })
      end

      # if the end_time has not reached now (CommercialBlock should be playing)
      if log_entry.estimated_end_time < Time.now
        spin = PL.db.get_spin_by_current_position({ schedule_id: @id, current_position: (playlist.last.current_position + 1) })
        if spin.commercial_leads_in
          log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                                audio_block_id: station.next_commercial_block.id,
                                                airtime: (spin.estimated_airtime - station.secs_of_commercial_per_hour/2),
                                                listeners_at_start: 0,
                                                listeners_at_finish: 0,
                                                duration: (station.secs_of_commercial_per_hour/2 * 1000)
                                              })
          station.advance_commercial_block
        end
      end

      PL.db.update_log_entry({ id: log_entry.id, listeners_at_finish: nil })
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
    def format_playlist(attrs)
      # return an empty array if given one
      if attrs[:playlist] == []
        return []
      end

      # if no start_time given, use 1st estimated_airtime
      if !attrs[:start_time]
        attrs[:start_time] = attrs[:playlist][0].estimated_airtime
      end

      max_position = attrs[:playlist].last.current_position
      time_tracker = attrs[:start_time]

      # adjust for the 1st spin if commercial leads in
      if attrs[:playlist][0].commercial_leads_in
        time_tracker -= station.secs_of_commercial_per_hour/2
      end

      modified_playlist = []

      attrs[:playlist].each do |spin|
        # if it's time for a commercial
        if spin.commercial_leads_in
          if attrs[:insert_commercials?]
            modified_playlist << PL::CommercialBlock.new(
                                        { schedule_id: spin.schedule_id,
                                          estimated_airtime: time_tracker,
                                          duration: station.secs_of_commercial_per_hour/2 })
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
        airtime = spin.estimated_airtime
      else
        # set to a valid minimum value
        airtime = Time.local(1970,1,1)
      end
      airtime
    end


    def now_playing
      if !active?
        self.bring_current
      end

      PL.db.get_recent_log_entries({ station_id: @station_id, count: 1 })[0]
    end


    def next_spin
      self.bring_current

      # if it should be a commercial
      if find_commercial_count(now_playing.airtime) != find_commercial_count(now_playing.estimated_end_time)
        return @station.next_commercial_block
      else
        return PL.db.get_next_spin(@id)
      end
    end

    ########################################################
    #  get_program                                         #
    ########################################################
    # takes start_time, end_time, returns array of spins   #
    ########################################################

    def get_program(attrs={})
      if !attrs[:start_time]
        attrs[:start_time] = Time.now
      end

      if !attrs[:end_time]
        attrs[:end_time] = attrs[:start_time] + (3*60*60)
      end

      playlist = PL.db.get_partial_playlist({ start_time: attrs[:start_time], end_time: attrs[:end_time], schedule_id: @id })

      # if it's out of range try extending the playlist
      if playlist.size == 0
        self.generate_playlist

        playlist = PL.db.get_partial_playlist({ start_time: attrs[:start_time], end_time: attrs[:end_time], schedule_id: @id })

        # if that still didn't work return an empty array
        if playlist.size == 0
          return []
        end
      end
      
      # if there's a leading spin, add it
      leading_spin = PL.db.get_spin_by_current_position({ current_position: (playlist[0].current_position - 1),
                                                          schedule_id: @id })
      playlist.unshift(leading_spin) unless !leading_spin


      playlist = self.format_playlist({ playlist: playlist, insert_commercials?: true })

      playlist 
    end
  end
end