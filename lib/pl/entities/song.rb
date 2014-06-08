module PL
	class Song < Entity
		attr_accessor :id, :artist, :title, :album, :duration, :key, :created_at, :updated_at

		def initialize(attrs)
			super(attrs)
		end
	end
end
