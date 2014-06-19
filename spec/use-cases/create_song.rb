module PL
	class CreateSong < UseCase
		def run(attrs)
			fp = PL::SongProcessor.new

		end
	end
end