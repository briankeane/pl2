module PL
  class CommercialBlock < Entity

    attr_accessor :id, :duration, :estimated_airtime, :commercials, :station_id, :cb_position, :audio_file, :current_position

    def initialize(attrs)
      # store default values if necessary
      attrs[:duration] ||= 180000
      attrs[:commercials] ||= []
      super(attrs)
    end

    def commercials_follow?
      false
    end

    def estimated_end_time
      estimated_airtime + @duration/1000
    end

    def airtime_in_ms
      @estimated_airtime.to_f * 1000
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      hash
    end
  end
end