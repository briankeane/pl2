module PL
	class Station < Entity
		attr_accessor :id, :secs_of_commercial_per_hour, :user_id,
							:heavy, :medium, :light, :created_at, :updated_at

		def initialize(attrs)
			super(attrs)
		end
	end
end