require 'date'
require 'chronic'
require 'aws-sdk'
require 'tempfile'
require 'timezone'
require 'active_support'
require 'date'

module PL
  class Station < Entity
    attr_accessor :id, :secs_of_commercial_per_hour, :user_id, :station_id
    attr_accessor :spins_per_week, :created_at, :updated_at
    attr_accessor :current_playlist_end_time, :original_playlist_end_time
    attr_accessor :next_commercial_block
    attr_accessor :last_commercial_block_aired
    attr_accessor :id, :station_id, :current_playlist_end_time
    attr_accessor :original_playlist_end_time, :next_commercial_block
    attr_accessor :last_accurate_current_position, :next_commercial_block_id
    attr_accessor :average_daily_listeners_calculation_date
    attr_writer   :average_daily_listeners, :genres

    # Station-specific constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400
    SPINS_WITHOUT_REPEAT = 35
    
    def initialize(attrs)
      Time.zone = self.timezone || 'Central Time (US & Canada)'
      attrs[:secs_of_commercial_per_hour] ||= PL::DEFAULT_SECS_OF_COMMERCIAL_PER_HOUR
      attrs[:spins_per_week] ||= {}
      super(attrs)
    end

    def average_daily_listeners
      if @average_daily_listeners_calculation_date && (Date.today - @average_daily_listeners_calculation_date < 1)
        @average_daily_listeners
      else
        self.update_airtimes({ end_time: Date.today.to_datetime })
        log_entries = PL.db.get_log_entries_by_date_range({ station_id: @id,
                                                            start_date: Date.today - 1})
        if log_entries.size == 0
          sum = 0.0
          @average_daily_listeners = 0.0
        else
          sum = log_entries.inject(0.0){ |sum,entry| sum += (entry.listeners_at_finish || 0) }
          @average_daily_listeners = sum.to_f/log_entries.size.to_f
        end
          
        @average_daily_listeners_calculation_date = Date.today
        
        # store result in the db
        PL.db.update_station({ id: @id, 
                          average_daily_listeners: @average_daily_listeners,
                            average_daily_listeners_calculation_date: @average_daily_listeners_calculation_date })
        return @average_daily_listeners
      end
    end

    def timezone
      if !user
        'Central Time (US & Canada)'
      else
        user.timezone
      end
    end

    def user
      @user ||= PL.db.get_user(@user_id)
    end

    ##################################################################
    #     create_sample_array                                        #
    ##################################################################
    #  This method creates an array of samples for the playlist      #
    #  generator to randomly select from.  It populates each song    #
    #  in the correct ratio.                                         #
    #  The values are stored in the array as song objects (not ids)  #
    ##################################################################

    def create_sample_array
      sample_array = []

      # add songs to sample-array in correct ratios
      @spins_per_week.each do |k,v|
        v.times { sample_array.push(PL::db.get_song(k)) }
      end

      sample_array
    end

    def get_commercial_block_for_broadcast(current_position)
      cb = PL.db.get_commercial_block_by_current_position({ station_id: @id, current_position: current_position })
      if !cb
        cf = PL::CommercialBlockFactory.new
        cb = cf.construct_block({ station: self, current_position: current_position })
      end

      cb
    end  

    def log_end_time
      last_spin_played = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
      
      if !last_spin_played
        return nil
      end
      
      last_spin_ended = last_spin_played.airtime + last_spin_played.duration/1000
      last_spin_ended
    end

    def just_played
      PL.db.get_recent_log_entries({ station_id: @id, count: 2 })[0]
    end

    def final_log_entry
      PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
    end


    def playlist_exists?
      PL.db.playlist_exists?(@id)
    end

    def log_exists?
      PL.db.log_exists?(@station_id)
    end

    def generate_playlist(playlist_end_time=nil)
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)
      
      self.update_airtimes

      # keep end_time within range
      if playlist_end_time
        playlist_end_time = [playlist_end_time, next_thursday_midnight].min
      else
        playlist_end_time = next_thursday_midnight
      end

      sample_array = self.create_sample_array
      
      # if playlist exists but is used up
      if (current_playlist.size == 0) && log_exists?

        # station 1 spin to get things started
        spin =  PL.db.create_spin({ station_id: @id,
                            audio_block_id: sample_array.sample.id,
                            current_position: self.final_log_entry.current_position + 1,
                            airtime: self.final_log_entry.estimated_end_time })
        @last_accurate_current_position = spin.current_position
        current_playlist = PL.db.get_full_playlist(@id)
      end

      # set max_position and time_tracker initial values
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.zone.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
        if current_playlist.last.commercials_follow?
          time_tracker += self.secs_of_commercial_per_hour/2
        end
      end

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
              (recently_played_song_ids.size >= self.spins_per_week.size - 1))
          recently_played_song_ids.shift
        end

        spin =  Spin.new({ station_id: @id,
                            audio_block_id: song.id,
                            current_position: (max_position += 1),
                            airtime: time_tracker })
        spins << spin

        time_tracker += (spin.duration/1000)

        if spin.commercials_follow?
          time_tracker += self.secs_of_commercial_per_hour/2
        end

      end #end while

      PL.db.mass_add_spins(spins)

      @original_playlist_end_time = time_tracker
      
      @last_accurate_current_position = spins.last.current_position unless (spins.size == 0)
      PL.db.update_station({ id: @id, last_accurate_current_position: @last_accurate_current_position })
      @current_playlist_end_time = time_tracker

      #if it's the first playlist, start the station
      if PL.db.get_recent_log_entries({ station_id: @id, count: 1 }).size == 0
        first_spin = PL.db.get_next_spin(@id)
        PL.db.create_log_entry({ station_id: @id,
                                 current_position: first_spin.current_position,
                                 audio_block_id: first_spin.audio_block_id,
                                 airtime: first_spin.airtime,
                                 duration: first_spin.duration
                                 })
        PL.db.delete_spin(first_spin.id)
      end
    end

    def end_time
      self.update_airtimes
      last_spin = PL.db.get_last_spin(@id)
      if !last_spin
        return nil
      else
        return last_spin.estimated_end_time
      end
    end

    def active?
      if !self.log_end_time
        return nil
      else
        return (self.log_end_time.utc < Time.now.utc) ? false : true
      end
    end

                 
    def update_airtimes(attrs = {})
      # if there's no playlist yet, just exit
      if !playlist_exists?
        return false
      end

      # exit if an end_time is provided and it's already accurate
      if attrs[:end_time] && (attrs[:end_time] < last_accurate_airtime)
        return false
      end

      # exit if a current_position is provided and it's already accurate
      if attrs[:current_position] && (attrs[:current_position] < @last_accurate_current_position)
        return false
      end

      # if the last_accurate_current_position is after the log, use it as the starting point
      
      if @last_accurate_current_position && (@last_accurate_current_position > self.final_log_entry.current_position)
        playlist = PL.db.get_playlist_by_current_positions({ station_id: @id,
                                                                     starting_current_position: @last_accurate_current_position })
        
        time_tracker = playlist[0].airtime

      else  # otherwise use the log as the starting point
        playlist = PL.db.get_full_playlist(@id)
        time_tracker = final_log_entry.estimated_end_time

        # account for a lead-in commercial if necessary
        if self.final_log_entry.commercials_follow?
          time_tracker += self.secs_of_commercial_per_hour/2
        end
      end

      # update the database
      playlist.each do |spin|

        spin = PL.db.update_spin({ id: spin.id,
                            airtime: time_tracker })
        
        @last_accurate_current_position = spin.current_position

        time_tracker += spin.duration/1000

        # account for a commercial if necessary
        if spin.commercials_follow?
          time_tracker += self.secs_of_commercial_per_hour/2
        end

        # break out if job finishes early
        if attrs[:end_time]
          if spin.airtime > attrs[:end_time]
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
      PL.db.update_station({ id: @id, last_accurate_current_position: @last_accurate_current_position })
    end

    def bring_current
      # if the station is already active or no playlist has been created, yet, do nothing
      if self.active? || (!playlist_exists? && !log_exists?)
        return
      end
      
      self.update_airtimes({ end_time: Time.now }) 

      playlist = PL.db.get_partial_playlist({ station_id: @id, end_time: Time.now })

      # if the playlist does not extend past now, regenerate
      if (playlist.size == 0) || (playlist.last.estimated_end_time < Time.now)
        self.generate_playlist(Time.now)
        playlist = PL.db.get_partial_playlist({ station_id: @id, end_time: Time.now })
      end

      # mark the last-started song as finished, add a commercial block if necessary
      log_entry = final_log_entry
      PL.db.update_log_entry({ id: log_entry.id,
                              listeners_at_finish: 0 })

      if log_entry.commercials_follow?
          log_entry = PL.db.create_log_entry({ station_id: @id,
                                              airtime: log_entry.estimated_end_time,
                                              listeners_at_start: 0,
                                              listeners_at_finish: 0,
                                              current_position: log_entry.current_position,
                                              is_commercial_block: true,
                                              duration: (self.secs_of_commercial_per_hour/2 * 1000)
                                            })
      end



      playlist.each do |spin|
        log_entry = PL.db.create_log_entry({ station_id: @id,
                                    listeners_at_start: 0,
                                    listeners_at_finish: 0,
                                    audio_block_id: spin.audio_block_id,
                                    duration: spin.duration,
                                    airtime: spin.airtime,
                                    current_position: spin.current_position })
        PL.db.delete_spin(spin.id)

        # break out if the spin is the current spin
        if spin.estimated_end_time > Time.now
          break
        end

        if spin.commercials_follow?
          log_entry = PL.db.create_log_entry({ station_id: @id,
                                              current_position: spin.current_position,
                                              airtime: spin.estimated_end_time,
                                              listeners_at_start: 0,
                                              listeners_at_finish: 0,
                                              is_commercial_block: true,
                                              duration: (self.secs_of_commercial_per_hour/2 * 1000)
                                            })
        end

        # break out if the commercial is the current spin
        if log_entry.estimated_end_time > Time.now
          break
        end

      end

      PL.db.update_log_entry({ id: log_entry.id, listeners_at_finish: nil })
    end

    def last_accurate_airtime
      spin = PL.db.get_spin_by_current_position({ station_id: @id, current_position: @last_accurate_current_position })
      if spin
        airtime = spin.airtime
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

      PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
    end

    ########################################################
    #  get_program                                         #
    ########################################################
    # takes start_time, end_time, returns array of spins   #
    ########################################################

    def get_program(attrs={})
      if !attrs[:start_time]
        attrs[:start_time] = Time.now
        current_program = true
      end

      if !attrs[:end_time]
        attrs[:end_time] = attrs[:start_time] + (3*60*60)
      end

      if last_accurate_airtime < attrs[:end_time]
        self.update_airtimes({ end_time: attrs[:end_time] + (60*60) })
      end

      playlist = PL.db.get_partial_playlist({ start_time: attrs[:start_time], end_time: attrs[:end_time], station_id: @id })


      # if it's out of range try extending the playlist
      if playlist.size == 0
        self.generate_playlist

        playlist = PL.db.get_partial_playlist({ start_time: attrs[:start_time], end_time: attrs[:end_time], station_id: @id })

        # if that still didn't work return an empty array
        if playlist.size == 0
          return []
        end
      end
      
      # if there's not enough songs, extend the playlist
      if playlist.last.estimated_end_time < attrs[:end_time]
        self.generate_playlist(attrs[:end_time])
        playlist = PL.db.get_partial_playlist({ start_time: attrs[:start_time], end_time: attrs[:end_time], station_id: @id })
      end
      
      # trim off non-updated spins
      playlist.delete_if { |spin| spin.current_position > @last_accurate_current_position }
      
      playlist_with_commercial_blocks = []


      if current_program
        previous_spin = now_playing
      else
        previous_spin = PL.db.get_spin_by_current_position({ station_id: @id, current_position: playlist[0].current_position - 1 })
      end

      # if it starts with a commercial, add it before starting
      if previous_spin && previous_spin.commercials_follow?
        playlist_with_commercial_blocks << PL::CommercialBlock.new({ station_id: @id,
                                                airtime: previous_spin.estimated_end_time,
                                                duration: self.secs_of_commercial_per_hour/2,
                                                current_position: previous_spin.current_position })
      end

      playlist.each do |spin|
        playlist_with_commercial_blocks << spin
        if spin.commercials_follow?
          playlist_with_commercial_blocks << PL::CommercialBlock.new({ station_id: @id,
                                                airtime: spin.estimated_end_time,
                                                duration: self.secs_of_commercial_per_hour/2,
                                                current_position: spin.current_position })
        end
      end

      # add currently playing song if current playlist
      if current_program
        if self.now_playing.is_commercial_block
          playlist_with_commercial_blocks.unshift(PL::CommercialBlock.new({ current_position: self.now_playing.current_position,
                                                      airtime: self.now_playing.airtime,
                                                      duration: self.now_playing.duration,
                                                      station_id: @id }))
        else
          playlist_with_commercial_blocks.unshift(self.now_playing)
        end
      end

      playlist_with_commercial_blocks 
    end

    def get_program_by_current_positions(attrs) 
      self.update_airtimes({ current_position: attrs[:ending_current_position] + 10 })

      playlist = PL.db.get_playlist_by_current_positions({ station_id: @id,
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
          playlist_with_commercial_blocks << PL::CommercialBlock.new({ station_id: @id,
                                                                        airtime: spin.estimated_end_time,
                                                                        duration: self.secs_of_commercial_per_hour/2,
                                                                        current_position: spin.current_position })
        end
      end

      playlist_with_commercial_blocks
    end

    def insert_spin(attrs)
      added_spin = PL.db.add_spin({ add_position: attrs[:add_position],
                                    station_id: @id,
                                    audio_block_id: attrs[:audio_block_id] })
      @last_accurate_current_position = attrs[:add_position] - 1
      self.update_airtimes({ current_position: attrs[:add_position] })
      PL.db.update_station({ id: @id, last_accurate_current_position: @last_accurate_current_position })
      added_spin = PL.db.get_spin(added_spin.id)   # for updated airtime
      return added_spin
    end

    def move_spin(attrs)
      moved_spin = PL.db.move_spin({ old_position: attrs[:old_position],
                                     new_position: attrs[:new_position],
                                    station_id: @id })

      min_current_position = [attrs[:old_position], attrs[:new_position]].min - 1

      if min_current_position < @last_accurate_current_position
        @last_accurate_current_position = min_current_position
        PL.db.update_station({ id: @id, last_accurate_current_position: min_current_position })
      end
      return moved_spin
    end

    def clear
      self.bring_current
      PL.db.delete_spins_for_station(@id)
    end

    # final_log_entry does not bring the station current
    def final_log_entry
      PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
    end

    def listener_count
      PL.db.get_listener_count({ station_id: @id })
    end

    def genres
      hash = Hash.new(0)
      @spins_per_week.each do |song_id,song|
        PL.db.get_genres(song_id).each do |genre|
          hash[genre] += 1
        end
      end

      max_value = hash.values.max

      percentages_hash = {}
      hash.each { |k,v| percentages_hash[k] = v.to_f/max_value.to_f }
      return percentages_hash
    end


  end
end
