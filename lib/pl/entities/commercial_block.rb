module PL
  class CommercialBlock < Entity

    attr_accessor :id, :duration, :estimated_airtime, :commercials, :station_id, :cb_position, :audio_file

    def initialize(attrs)
      # store default values if necessary
      attrs[:duration] ||= 180000
      attrs[:commercials] ||= []
      super(attrs)
    end
  end
end