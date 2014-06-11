module PL
	class Station < Entity
		attr_accessor :id, :secs_of_commercial_per_hour, :user_id,
							:rotation_levels, :created_at, :updated_at

		def initialize(attrs)

			
			heavy = attrs.delete(:heavy)
			medium = attrs.delete(:medium)
			light = attrs.delete(:light)

			heavy ||= {}
			medium ||= {}
			light ||= {}

			#store rotation_levels
			@rotation_levels = {}
			heavy.each do |song_id|
				@rotation_levels[song_id] = ROTATION_LEVEL_HEAVY
			end

			medium.each do |song_id|
				@rotation_levels[song_id] = ROTATION_LEVEL_MEDIUM
			end

			light.each do |song_id|
				@rotation_levels[song_id] = ROTATION_LEVEL_LIGHT
			end
			
			super(attrs)
		end
	end
end
