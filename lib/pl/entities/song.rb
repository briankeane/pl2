  module PL
  class Song < Entity
    attr_accessor :id, :artist, :title, :album, :duration
    attr_accessor :key, :created_at, :updated_at, :audio_file, :echo_id

    def initialize(attrs)
      super(attrs)
    end
  end
end
