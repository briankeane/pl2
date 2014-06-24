module PL
  class Commentary < Entity
    attr_accessor :id, :station_id, :duration, :key

    def initialize(attrs)
      super(attrs)
    end
  end
end