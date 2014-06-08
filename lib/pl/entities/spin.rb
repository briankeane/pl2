module PL
	class Spin < Entity
		attr_accessor :id, :current_position, :audio_block_type, :audio_block_id

		def initialize(attrs)
			super(attrs)
		end
	end
end