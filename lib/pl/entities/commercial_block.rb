module PL
  class CommercialBlock < Entity

    attr_accessor :id, :duration, :played_at, :estimated_airtime, :commercials, :station_id, :cb_position

    def initialize(attrs)
      attrs[:duration] ||= 180000
      attrs[:commercials] ||= []
      super(attrs)
    end
  end
end