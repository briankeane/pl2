module PL
	class Commercial < Entity
		attr_accessor :id, :sponsor, :duration, :key

		def initialize(attrs)
			super(attrs)
		end
	end
end