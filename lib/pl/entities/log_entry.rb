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

  end
end
