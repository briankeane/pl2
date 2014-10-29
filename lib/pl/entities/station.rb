require 'chronic'
require 'aws-sdk'
require 'tempfile'

module PL
  class Station < Entity
    attr_accessor :id, :secs_of_commercial_per_hour, :user_id, :schedule_id
    attr_accessor :spins_per_week, :created_at, :updated_at
    attr_accessor :current_playlist_end_time, :original_playlist_end_time
    attr_accessor :next_commercial_block

    # Station-specific constants
    MS_IN_WEEK = 604.8e+6
    SECONDS_IN_WEEK = MS_IN_WEEK/1000
    SECONDS_IN_DAY = 86400

    def initialize(attrs)
      attrs[:schedule_id]  ||= PL.db.create_schedule({ station_id: @id }).id
      attrs[:secs_of_commercial_per_hour] ||= PL::DEFAULT_SECS_OF_COMMERCIAL_PER_HOUR
      attrs[:spins_per_week] ||= {}
      super(attrs)
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

    def schedule
      @schedule ||= PL.db.get_schedule(@schedule_id)
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

    def now_playing
      schedule.now_playing
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
      schedule.next_spin
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

    def advance_commercial_block
      cf = PL::CommercialBlockFactory.new
      @next_commercial_block = cf.construct_block(self)
      return @next_commercial_block
    end
    

    ##################################################################
    #     active?                                                    #
    ##################################################################
    #  checks whether or not the station is currently active         #
    #  -----------------------------------------------------         #
    #  returns TRUE or FALSE                                         #
    ##################################################################
    def active?
      schedule.active?
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

    def end_time
      schedule.update_estimated_airtimes
      last_scheduled_spin = PL.db.get_last_spin(@id)
      last_scheduled_spin.estimated_airtime + last_scheduled_spin.duration/1000
    end

    def offset   # measurement of shift in end_time
      @original_playlist_end_time - self.end_time
    end

    def final_log_entry
      PL.db.get_recent_log_entries({ station_id: @id, count: 1 })[0]
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
