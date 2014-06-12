module PL
	class LogEntry < Entity
		attr_accessor :station_id, :current_position, :audio_block_type, :audio_block_id
		attr_accessor :airtime, :listeners_at_start, :listeners_at_finish, :id

		def initialize(attrs)
			super(attrs)
		end
	end
end
