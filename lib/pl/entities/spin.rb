module PL
  class Spin < Entity
    attr_accessor :id, :current_position, :created_at, :updated_at
    attr_accessor :station_id, :estimated_airtime
    attr_reader :audio_block_id

    def initialize(attrs)
      super(attrs)
      @audio_block = PL.db.get_audio_block(audio_block_id)
    end

    # if audio_block_id is updated, update audio_block, too
    def audio_block_id=(new_id)
      @audio_block_id = new_id
      @audio_block = PL.db.get_audio_block(audio_block_id)
    end

    def audio_block
      @audio_block ||= PL.db.get_audio_block(audio_block_id)
    end

    ###############################################
    # Temporary Stub for Duration... allows other #
    # functions to be developed. Amend later to   #
    # account for offsets                         #
    ###############################################
    def duration
      self.audio_block.duration
    end

    def estimated_end_time
      self.estimated_airtime + self.duration/1000
    end

  end
end