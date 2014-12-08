module PL
  class ListeningSession < Entity
    attr_accessor :id, :first_current_position, :last_current_position
    attr_accessor :start_time, :end_time, :listener_id, :station_id

    def initialize(attrs)
      super(attrs)
    end
  end
end