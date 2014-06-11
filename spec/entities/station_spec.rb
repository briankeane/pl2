require 'spec_helper'

describe 'a station' do
	it 'is created with an id, secs_of_commercial_per_hour, user_id, and heavy, medium, and light rotation arrays' do
		song1 = PL::Song.new({ id: 1 })
		song2 = PL::Song.new({ id: 2 })
		song3 = PL::Song.new({ id: 3 })
		station = PL::Station.new({ id: 1,
		   secs_of_commercial_per_hour: 3,
		                       user_id: 2,
		                         heavy: [song1.id],
		                        medium: [song2.id],
		                         light: [song3.id],
		                         created_at: Time.new(1970),
		                         updated_at: Time.new(1970, 1, 2) })
		expect(station.id).to eq(1)
		expect(station.secs_of_commercial_per_hour).to eq(3)
		expect(station.user_id).to eq(2)
		expect(station.rotation_levels[song1.id]).to eq(PL::ROTATION_LEVEL_HEAVY)
		expect(station.rotation_levels[song2.id]).to eq(PL::ROTATION_LEVEL_MEDIUM)
		expect(station.rotation_levels[song3.id]).to eq(PL::ROTATION_LEVEL_LIGHT)
		expect(station.created_at).to eq(Time.new(1970))
		expect(station.updated_at).to eq(Time.new(1970, 1, 2))
	end
end