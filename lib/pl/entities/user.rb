module PL
	class User < Entity
		attr_accessor :id, :twitter, :twitter_uid, :email
		attr_accessor :birth_year, :gender, :created_at, :updated_at

		def intialize(attrs)
			super(attrs)
		end
	end
end
