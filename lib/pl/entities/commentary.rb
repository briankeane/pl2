module PL
  class Commentary < Entity
    attr_accessor :id, :schedule_id, :duration, :key, :audio_file

    def initialize(attrs)
      super(attrs)
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      hash
    end
  end
end