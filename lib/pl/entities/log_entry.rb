module PL
  class LogEntry < Entity
    attr_accessor :station_id, :current_position, :audio_block_id
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
    
  end
end
