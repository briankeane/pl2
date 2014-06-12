module PL
  class CommercialBlock < Entity

    attr_accessor :id, :duration, :played_at, :estimated_air_time, :commercials

    def initialize(attrs)
      attrs[:duration] ||= 180000
      attrs[:commercials] ||= []
      super(attrs)
    end
  end
end