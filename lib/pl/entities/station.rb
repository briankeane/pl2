module PL
	class Station < Entity
		attr_accessor :id, :secs_of_commercial_per_hour, :user_id
		attr_accessor	:spins_per_week, :created_at, :updated_at
		attr_accessor :current_playlist_end_time, :original_playlist_end_time
		

		def initialize(attrs)

			
			heavy = attrs.delete(:heavy)
			medium = attrs.delete(:medium)
			light = attrs.delete(:light)

			heavy ||= {}
			medium ||= {}
			light ||= {}

			#store spins_per_week
			@spins_per_week = {}
			heavy.each do |song_id|
				@spins_per_week[song_id] = PL::HEAVY_ROTATION
			end

			medium.each do |song_id|
				@spins_per_week[song_id] = PL::MEDIUM_ROTATION
			end

			light.each do |song_id|
				@spins_per_week[song_id] = PL::LIGHT_ROTATION
			end
			
			super(attrs)
		end

	end
end
