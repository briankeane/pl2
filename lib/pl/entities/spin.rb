module PL
	class Spin < Entity
		attr_accessor :id, :current_position, :audio_block_type, :audio_block_id, :created_at, :updated_at
		attr_accessor :station_id, :estimated_airtime

		def initialize(attrs)
			super(attrs)
		end
	end
end