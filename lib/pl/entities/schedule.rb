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

      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.zone.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
        if current_playlist.last.commercials_follow?
          time_tracker += @station.secs_of_commercial_per_hour/2
        end
      end

      sample_array = station.create_sample_array

      recently_played_song_ids = []
      spins = []


      while time_tracker < playlist_end_time
        song = sample_array.sample

        # pick again until it hasn't been played recently
        while recently_played_song_ids.include?(song.id)
          song = sample_array.sample
        end

        recently_played_song_ids << song.id

        # if the recently_played_song_ids is at max size, delete the first song
        if ((recently_played_song_ids.size >= SPINS_WITHOUT_REPEAT) ||
              (recently_played_song_ids.size >= station.spins_per_week.size - 1))
          recently_played_song_ids.shift
        end
        
        spin =  Spin.new({ schedule_id: @id,
                            audio_block_id: song.id,
                            current_position: (max_position += 1),
                            estimated_airtime: time_tracker })
        spins << spin
        
        time_tracker += (spin.duration/1000)
        
        if spin.commercials_follow?
          time_tracker += station.secs_of_commercial_per_hour/2
        end

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

                 
    def update_estimated_airtimes(attrs = {})
      # if there's no playlist yet, just exit

      if !playlist_exists?
        return false
      end

      # exit if an endtime is provided and it's already accurate
      if attrs[:endtime] && (attrs[:endtime] < last_accurate_airtime)
        return false
      end

      # exit if a current_position is provided and it's already accurate
      if attrs[:current_position] && (attrs[:current_position] < @last_accurate_current_position)
        return false
      end

      # if the last_accurate_current_position is after the log, use it as the starting point
      if @last_accurate_current_position > final_log_entry.current_position
        playlist = PL.db.get_playlist_by_current_positions({ schedule_id: @id,
                                                                     starting_current_position: @last_accurate_current_position })
        
        time_tracker = playlist[0].estimated_airtime

      else  # otherwise use the log as the starting point
        playlist = PL.db.get_full_playlist(@id)
        time_tracker = final_log_entry.estimated_end_time

        # account for a lead-in commercial if necessary
        if station.final_log_entry.commercials_follow?
          time_tracker += station.secs_of_commercial_per_hour/2
        end
      end

      # update the database
      playlist.each do |spin|

        spin = PL.db.update_spin({ id: spin.id,
                            estimated_airtime: time_tracker })
        
        @last_accurate_current_position = spin.current_position

        if spin.audio_block.is_a?(PL::CommercialBlock)
          binding.pry
        end

        time_tracker += spin.duration/1000

        # account for a commercial if necessary
        if spin.commercials_follow?
          time_tracker += station.secs_of_commercial_per_hour/2
        end

        # break out if job finishes early
        if attrs[:endtime]
          if spin.estimated_airtime > attrs[:endtime]
            break
          end
        end

        # break out if final last_accurate_current_position is passed
        if attrs[:current_position]
          if spin.current_position > attrs[:current_position]
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
      
      self.update_estimated_airtimes({ endtime: Time.now })

      playlist = PL.db.get_partial_playlist({ schedule_id: @id, end_time: Time.now })

      # mark the last-started song as finished, add a commercial block if necessary
      unfinished_log = final_log_entry
      PL.db.update_log_entry({ id: unfinished_log.id,
                              listeners_at_finish: 0 })

      if unfinished_log.commercials_follow?
          log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                              audio_block_id: station.next_commercial_block.id,
                                              airtime: unfinished_log.estimated_end_time,
                                              listeners_at_start: 0,
                                              listeners_at_finish: 0,
                                              current_position: unfinished_log.current_position,
                                              duration: (station.secs_of_commercial_per_hour/2 * 1000)
                                            })
      end

      playlist.each do |spin|
        log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                    listeners_at_start: 0,
                                    listeners_at_finish: 0,
                                    audio_block_id: spin.audio_block_id,
                                    duration: spin.duration,
                                    airtime: spin.estimated_airtime,
                                    current_position: spin.current_position })
        PL.db.delete_spin(spin.id)

        # break out if the spin is the current spin
        if spin.estimated_end_time > Time.now
          break
        end

        if spin.commercials_follow?
          log_entry = PL.db.create_log_entry({ station_id: @station_id,
                                              audio_block_id: station.next_commercial_block.id,
                                              current_position: spin.current_position,
                                              airtime: spin.estimated_end_time,
                                              listeners_at_start: 0,
                                              listeners_at_finish: 0,
                                              duration: (station.secs_of_commercial_per_hour/2 * 1000)
                                            })
          station.advance_commercial_block
        end

        # break out if the commercial is the current spin
        if log_entry.estimated_end_time > Time.now
          break
        end

      end

      PL.db.update_log_entry({ id: log_entry.id, listeners_at_finish: nil })
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

      if last_accurate_airtime < attrs[:end_time]
        self.update_estimated_airtimes({ endtime: attrs[:end_time] + (60*60) })
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
      
      # trim off non-updated spins
      playlist.delete_if { |spin| spin.current_position > @last_accurate_current_position }
      
      # if there's a leading spin, add it
      leading_spin = PL.db.get_spin_by_current_position({ current_position: (playlist[0].current_position - 1),
                                                          schedule_id: @id })
      playlist.unshift(leading_spin) unless !leading_spin

      playlist_with_commercial_blocks = []
      
      playlist.each do |spin|
        playlist_with_commercial_blocks << spin
        if spin.commercials_follow?
          playlist_with_commercial_blocks << PL::CommercialBlock.new({ schedule_id: spin.schedule_id,
                                                estimated_airtime: spin.estimated_end_time,
                                                duration: station.secs_of_commercial_per_hour/2 })
        end
      end


      playlist_with_commercial_blocks 
    end

    def get_program_by_current_positions(attrs) 
      self.update_estimated_airtimes({ current_position: attrs[:ending_current_position] + 10 })

      playlist = PL.db.get_playlist_by_current_positions({ schedule_id: @id,
                                                          starting_current_position: attrs[:starting_current_position],
                                                          ending_current_position: attrs[:ending_current_position] })
      
      # return an empty array if no spins are found
      if playlist.size == 0
        return []
      end

      playlist_with_commercial_blocks = []
      playlist.each do |spin|
        playlist_with_commercial_blocks << spin
        if spin.commercials_follow?
          playlist_with_commercial_blocks << PL::CommercialBlock.new({ schedule_id: spin.schedule_id,
                                                                        estimated_airtime: spin.estimated_end_time,
                                                                        duration: station.secs_of_commercial_per_hour/2 })
        end
      end

      playlist_with_commercial_blocks
    end

    def insert_spin(attrs)
      added_spin = PL.db.add_spin({ add_position: attrs[:add_position],
                                    schedule_id: @id,
                                    audio_block_id: attrs[:audio_block_id] })
      @last_accurate_current_position = attrs[:add_position] - 1
      PL.db.update_schedule({ id: @id, last_accurate_current_position: @last_accurate_current_position })
      return added_spin
    end

    def move_spin(attrs)
      moved_spin = PL.db.move_spin({ old_position: attrs[:old_position],
                                     new_position: attrs[:new_position],
                                    schedule_id: @id })

      min_current_position = [attrs[:old_position], attrs[:new_position]].min - 1

      if min_current_position < @last_accurate_current_position
        @last_accurate_current_position = min_current_position
        PL.db.update_schedule({ id: @id, last_accurate_current_position: min_current_position })
      end

      return moved_spin
    end

    # unlike now_playing, final_log_entry does not bring the station current
    def final_log_entry
      PL.db.get_recent_log_entries({ station_id: @station_id, count: 1 })[0]
    end
  end
end