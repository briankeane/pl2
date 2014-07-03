require 'chronic'
require 'aws-sdk'
require 'tempfile'

module PL
  class Station < Entity
    attr_accessor :id, :secs_of_commercial_per_hour, :user_id
    attr_accessor :spins_per_week, :created_at, :updated_at
    attr_accessor :current_playlist_end_time, :original_playlist_end_time
    attr_accessor :next_commercial_block

    # Station-specific constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400

    def initialize(attrs)
      attrs[:secs_of_commercial_per_hour] ||= PL::DEFAULT_SECS_OF_COMMERCIAL_PER_HOUR
      attrs[:spins_per_week] ||= {}
      super(attrs)
    end

    #####################################################################
    #     make_log_current                                              #
    #####################################################################
    #  updates the logs if the station has been inactive                #
    #####################################################################
    def make_log_current

      playlist = PL.db.get_full_playlist(@id)

      # grab the last current_position in the log
      max_position = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0].current_position
      
      # IF the station's been off
      if !self.active?
        time_tracker = self.log_end_time

        # calibrate commercial_block_counter for start-time
        commercial_block_counter = (time_tracker.to_f/1800.0).floor

        #adjust commercial_block_counter for cases where 1st spin should be a commercial_block
        if (self.last_log_entry.airtime.to_f/1800.0).floor != commercial_block_counter
          commercial_block_counter -= 1
        end

        # set up an index to go through playlist array
        index = 0
        # get the log & playlist caught up
        while (time_tracker < Time.now) && (index < playlist.size)

          # add a commercial block if it's time
          if (time_tracker.to_f/1800.0).floor > commercial_block_counter
            commercial_block_counter += 1
            commercial_block = PL.db.create_commercial_block({ station_id: @id, 
                                                                duration: (@secs_of_commercial_per_hour/2) * 1000 })
            PL.db.create_log_entry({ station_id: @id,
                                      current_position: (max_position += 1),
                                      audio_block_id: commercial_block.id,
                                      airtime: time_tracker,
                                      duration: commercial_block.duration,
                                      listeners_at_start: 0,
                                      listeners_at_finish: 0 })
            time_tracker += (@secs_of_commercial_per_hour/2)

          # ELSE record the next scheduled spin
          else
            spin = playlist[index]
            log = PL.db.create_log_entry({ station_id: @id,
                                      current_position: (max_position += 1),
                                      audio_block_id: spin.audio_block_id,
                                      airtime: time_tracker,
                                      duration: spin.duration,
                                      listeners_at_start: 0,
                                      listeners_at_finish: 0 })
            PL.db.delete_spin(spin.id)
            time_tracker += log.duration/1000
            index += 1
          end
        end
      end  # end 'if station was asleep'
    end


    #####################################################################
    #     updated_estimated_airtimes                                    #
    #####################################################################
    #  updates the estimated airtimes, accounting for commercial blocks #
    #####################################################################

    def update_estimated_airtimes
      last_spin_played = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]


      last_spin_ended = last_spin_played.airtime + last_spin_played.duration/1000

      # if the station has been asleep
      if !self.active?
        self.make_log_current
        last_spin_played = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
        last_spin_ended = last_spin_played.airtime + last_spin_played.duration/1000
      end

      max_position = last_spin_played.current_position
      playlist = PL.db.get_full_playlist(@id)
      time_tracker = last_spin_ended

      # calibrate commercial_block_counter for start-time
      commercial_block_counter = (time_tracker.to_f/1800.0).floor

      #adjust commercial_block_counter for cases where 1st spin should be a commercial_block
        if (self.last_log_entry.airtime.to_f/1800.0).floor != commercial_block_counter
          commercial_block_counter -= 1
        end

      # iterate through the playlist and fix times
      playlist.each do |spin|

        # add a space for a commercial block if it's time
        if (time_tracker.to_f/1800.0).floor > commercial_block_counter
          commercial_block_counter += 1
          time_tracker += (@secs_of_commercial_per_hour/2)
        end

        updated_spin = PL.db.update_spin({ id: spin.id,
                                  estimated_airtime: time_tracker })
        time_tracker += updated_spin.duration/1000
      end
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
        v.times { sample_array << PL::db.get_song(k) }
      end

      sample_array
    end

    def now_playing
      if !self.active?
        self.make_log_current
      end

      return PL.db.get_recent_log_entries({station_id: @id, count: 1 })[0]
    end

    def now_playing_with_audio_file
      if !self.active?
        self.make_log_current
      end

      log_entry = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
      
      grabber = PL::AudioGrabber.new

      log_entry.audio_file = grabber.grab_audio(log_entry)

      return log_entry
    end

    def next_spin
      if !self.active?
        self.make_log_current
      end


      # if it should be a commercial (now_playing straddles the hour or the 1/2 hour)
      if (now_playing.airtime.to_f/1800.0).floor != (now_playing.estimated_end_time.to_f/1800.0).floor
        return next_commercial_block
      else
        return PL.db.get_spin_by_current_position({ station_id: @id,
                                                    current_position: (now_playing.current_position + 1) })
      end
    end

    def next_commercial_block
      if @next_commercial_block
        return @next_commercial_block
      else
        cf = PL::CommercialBlockFactory.new
        @next_commercial_block = cf.construct_block(self)
        return @next_commercial_block
      end
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
    #     1) proper hourly scheduling                                #
    #     2) station ids                                             #
    ##################################################################

    def generate_playlist
      # set up beginning and ending dates for comparison
      this_thursday_midnight = Chronic.parse('this thursday midnight')
      next_thursday_midnight = this_thursday_midnight + SECONDS_IN_WEEK
      current_playlist = PL.db.get_full_playlist(@id)
      time_tracker = nil

      # set max_position and time_tracker initial values
      if current_playlist.size == 0
        max_position = 0
        time_tracker = Time.now
      else
        max_position = current_playlist.last.current_position
        time_tracker = self.end_time
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

        spin = PL.db.create_spin({ station_id: @id,
                                     audio_block_id: song.id,
                                     current_position: (max_position += 1),
                                     estimated_airtime: time_tracker })

        time_tracker += (song.duration/1000)

      end  # endwhile

      @original_playlist_end_time = time_tracker

      #if it's the first playlist, start the station
      if PL.db.get_recent_log_entries({ station_id: @id, count: 1 }).size == 0
        first_spin = PL.db.get_full_playlist(@id).first
        PL.db.create_log_entry({ station_id: @id,
                                 current_position: first_spin.current_position,
                                 audio_block_id: song.id,
                                 airtime: first_spin.estimated_airtime,
                                 duration: first_spin.duration
                                 })
        PL.db.delete_spin(first_spin.id)
      end
    end
    ##################################################################
    #     get_program                                                #
    ##################################################################
    #  returns an array representing a piece of the playlist         #
    #  as it currently exists.                                       #
    #  if no start_time is given, it returns the current playlist    #
    #  default length is 2 hours                                     #
    ##################################################################
    def get_program(attrs)

      # set default values if necessary
      attrs[:start_time] ||= Time.now
      attrs[:end_time] ||= (attrs[:start_time] + (2*60*60))

      # give 5 min padding on either side of program
      attrs[:start_time] -= (5*60)
      attrs[:end_time] += (5*60)

      self.update_estimated_airtimes
      playlist = PL.db.get_partial_playlist({ station_id: @id,
                                              start_time: attrs[:start_time],
                                              end_time: attrs[:end_time] })
      
      # return an empty array if no spins found
      if playlist.size == 0
        return []
      end

      previous_spin = PL.db.get_spin_by_current_position({ station_id: @id,
                                                      current_position: (playlist[0].current_position - 1) })

      if !previous_spin
        previous_spin = now_playing
      end

      # iterate through the playlist and create the program
      program = []
      playlist.each do |spin|
        # add a commercial block if there's a space provided
        if previous_spin.estimated_end_time != spin.estimated_airtime
          commercial_block = PL::CommercialBlock.new({ station_id: @id,
                                                 duration: (@secs_of_commercial_per_hour/2 * 1000),
                                                 estimated_airtime: previous_spin.estimated_end_time })
          program << commercial_block
        end

        program << spin
        previous_spin = spin
      end

      program
    end

    ##################################################################
    #     active?                                                    #
    ##################################################################
    #  checks whether or not the station is currently active         #
    #  -----------------------------------------------------         #
    #  returns TRUE or FALSE                                         #
    ##################################################################
    def active?
      (self.log_end_time < Time.now) ? false : true
    end

    def log_end_time
      last_spin_played = PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
      last_spin_ended = last_spin_played.airtime + last_spin_played.duration/1000
    end

    def last_log_entry
      PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
    end

    def end_time
      self.update_estimated_airtimes
      last_scheduled_spin = PL.db.get_last_spin(@id)
      last_scheduled_spin.estimated_airtime + last_scheduled_spin.duration/1000
    end

    def offset   # measurement of shift in end_time
      @original_playlist_end_time - self.end_time
    end

    def adjust_offset(adjustment_date)  
      offset = self.offset
      current_playlist = PL.db.get_full_playlist(@id)
      first_spin_after_3am = current_playlist.find_by { |spin| (spin.estimated_airtime.day == adjustment_date.day + 1) &&
                                                                (spin.estimated_airtime.hour == 3) }

      if offset < 0
        # search for a song to add
        closest_in_duration = @spins_per_week.keys.min_by { |id| (offset.abs - PL.db.get_spin(id).duration/1000).abs }

        # if it's close enough to reduce the offset, add it
        if (offset.abs - closest_in_length.duration/1000).abs < offset.abs
          PL.db.add_spin({  station_id: @id,
                               current_position: (PL.first_spin_after_3am.current_position),
                               audio_block_id: closest_in_duration.id,
                               airtime: first_spin.estimated_airtime,
                               duration: first_spin.duration
                              })
        end
      else # if offset > 0
        # grab the 10 songs after 3am
        first_ten_songs = []
        index = current_playlist.index { |spin| spin.id == first_spin_after_3am }
        while first_ten_songs.size < 10
          if PL.db.get_audio_block(current_playlist[index].audio_block_id).is_a?(PL::Song)
            first_ten_songs << current_playlist[index]
            index += 1
          end
        end
        
        # if removing the spin will reduce the offset, remove the spin
        closest_in_duration = current_playlist.min_by { |spin| (offset.abs - spin.duration).abs }
        if (offset.abs - closest_in_duration.duration/1000).abs < offset.abs
          PL.db.remove_spin({ station_id: @id, current_position: closest_in_duration.current_position })
        end
      end
    end
  end
end
