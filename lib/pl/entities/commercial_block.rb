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
  end
end