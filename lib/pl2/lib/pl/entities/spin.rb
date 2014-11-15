module PL
  class Spin < Entity
    attr_accessor :id, :current_position, :created_at, :updated_at
    attr_accessor :schedule_id, :airtime
    attr_reader :audio_block_id

    def initialize(attrs)
      super(attrs)
      #@audio_block = PL.db.get_audio_block(audio_block_id)
    end

    # if audio_block_id is updated, get rid of newly invalidated audio_block, too
    def audio_block_id=(new_id)
      @audio_block_id = new_id
      @audio_block = nil
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
      self.airtime + self.duration/1000
    end

    def commercials_follow?
      if (self.airtime.to_f/1800.0).floor != (self.estimated_end_time.to_f/1800.0).floor
        return true
      else
        return false
      end
    end

    def airtime_in_ms
      @airtime.to_f * 1000
    end
  end
end