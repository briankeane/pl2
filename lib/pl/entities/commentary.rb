module PL
  class Commentary < Entity
    attr_accessor :id, :schedule_id, :duration, :key, :audio_file

    def initialize(attrs)
      super(attrs)
    end
  end
end