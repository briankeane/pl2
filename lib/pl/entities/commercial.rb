module PL
	class Commercial < Entity
		attr_accessor :id, :sponsor, :duration, :key, :created_at, :updated_at

		def initialize(attrs)
			super(attrs)
		end
	end
end