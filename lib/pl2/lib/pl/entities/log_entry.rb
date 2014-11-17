module PL
  class LogEntry < Entity
    attr_accessor :station_id, :current_position, :audio_block_id, :type, :is_commercial_block
    attr_accessor :airtime, :listeners_at_start, :listeners_at_finish, :id, :duration

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

    def to_hash
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