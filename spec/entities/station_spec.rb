require 'spec_helper'

describe 'a station' do
	it 'is created with an id, secs_of_commercial_per_hour, user_id, and heavy, medium, and light rotation arrays' do
		song1 = PL::Song.new({ id: 1 })
		song2 = PL::Song.new({ id: 2 })
		station = PL::Station.new({ id: 1,
		   secs_of_commercial_per_hour: 3,
		                       user_id: 2,
		                         heavy: [song1, song2],
		                        medium: [song1, song2],
		                         light: [song1, song2] })
		expect(station.id).to eq(1)
		expect(station.secs_of_commercial_per_hour).to eq(3)
		expect(station.user_id).to eq(2)
		expect(station.heavy.size).to eq(2)
		expect(station.medium.size).to eq(2)
		expect(station.light[0].id).to eq(1)
	end
end