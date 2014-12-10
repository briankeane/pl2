module PL
  class LogEntry < Entity
    attr_accessor :station_id, :current_position, :audio_block_id, :type, :is_commercial_block
    attr_accessor :airtime, :id, :duration
    attr_writer :listeners_at_start, :listeners_at_finish
    
    def initialize(attrs)
      super(attrs)
    end

    def estimated_end_time
    	airtime + @duration/1000
    end

    def audio_block
      @audio_block ||= PL.db.get_audio_block(@audio_block_id)
    end

    def commercials_follow?
      if (@airtime.to_f/1800.0).floor != (self.estimated_end_time.to_f/1800.0).floor
        return true
      else
        return false
      end
    end

    def airtime_in_ms
      @airtime.to_f * 1000
    end

    def listeners_at_start
      if @listeners_at_start == nil
        @listeners_at_start = PL.db.get_listener_count({ station_id: @station_id,
                                                          time: self.airtime })

        PL.db.update_station({ id: @id, listeners_at_start: @listeners_at_start})
      end
      @listeners_at_start
    end

    def listeners_at_finish
      if @listeners_at_finish == nil
        @listeners_at_finish = PL.db.get_listener_count({ station_id: @station_id,
                                                          time: self.estimated_end_time })
        PL.db.update_station({ id: @id, listeners_at_finish: @listeners_at_finish })
      end
      @listeners_at_finish
    end

    def to_hash
      # make sure listeners_at_start and listeners_at_finish have been calculated
      self.listeners_at_start
      self.listeners_at_finish

      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      hash[:audio_block] = audio_block.to_hash unless !audio_block
      hash[:estimated_end_time] = self.estimated_end_time
      hash[:airtime_in_ms] = self.airtime_in_ms unless !airtime
      hash[:commercials_follow?] = self.commercials_follow?
      hash
    end
  end
end