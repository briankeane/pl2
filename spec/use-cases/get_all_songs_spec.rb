require 'spec_helper'

describe 'GetAllSongs' do	
	it 'returns an empty array if no songs in db' do
		result = PL::GetAllSongs.run
		expect(result.success?).to eq(true)
		expect(result.all_songs). to eq([])
	end

	it 'gets all songs' do
		10.times do |i|
			PL.db.create_song({ title: "#{i} title",
													artist: "#{i} artist",
													album: "#{i } album",
													duration: i })
		end
	end
end