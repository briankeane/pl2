module PL
  class Song < Entity
    attr_accessor :id, :artist, :title, :album, :duration
    attr_accessor :key, :created_at, :updated_at, :audio_file, :echonest_id

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
