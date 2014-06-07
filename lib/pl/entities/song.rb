module PL
	class Song < Entity
		attr_accessor :id, :artist, :title, :album, :duration, :key

		def initialize(attrs)
			super(attrs)
		end
	end
end
