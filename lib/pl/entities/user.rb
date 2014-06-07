module PL
	class User < Entity
		attr_accessor :id, :twitter, :twitter_uid, :email
		attr_accessor :birth_year, :gender

		def intialize
			super.initialize
		end
	end
end
