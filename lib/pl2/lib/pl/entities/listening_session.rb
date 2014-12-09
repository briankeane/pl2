module PL
  class ListeningSession < Entity
    attr_accessor :id, :starting_current_position, :ending_current_position
    attr_accessor :start_time, :end_time, :listener_id, :station_id

    def initialize(attrs)
      super(attrs)
    end
  end
end