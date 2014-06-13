module PL
	class Spin < Entity
		attr_accessor :id, :current_position, :audio_block_type, :audio_block_id, :created_at, :updated_at
		attr_accessor :station_id, :estimated_airtime

		def initialize(attrs)
			super(attrs)
		end


		def audio_block
			case @audio_block_type
			when 'song'
				return PL.db.get_song(audio_block_id)
			when 'commercial'
				return PL.db.get_commercial(audio_block_id)
			when 'commentary'
				return PL.db.get_commentary(audio_block_id)
			end
		end

		###############################################
		# Temporary Stub for Duration... allows other #
		# functions to be developed. Amend later to   #
		# account for offsets                         #
		###############################################
		def duration
			self.audio_block.duration
		end
	end
end