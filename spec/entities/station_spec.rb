require 'spec_helper'

describe 'a station' do
	before(:each) do
		@song1 = PL::Song.new({ id: 1 })
		@song2 = PL::Song.new({ id: 2 })
		@song3 = PL::Song.new({ id: 3 })
		@station = PL::Station.new({ id: 1,
		   secs_of_commercial_per_hour: 3,
		                       user_id: 2,
		                         heavy: [@song1.id],
		                        medium: [@song2.id],
		                         light: [@song3.id],
		                         created_at: Time.new(1970),
		                         updated_at: Time.new(1970, 1, 2) })
	end

	it 'is created with an id, secs_of_commercial_per_hour, user_id, and heavy, medium, and light rotation arrays' do
		expect(@station.id).to eq(1)
		expect(@station.secs_of_commercial_per_hour).to eq(3)
		expect(@station.user_id).to eq(2)
		expect(@station.spins_per_week[@song1.id]).to eq(PL::HEAVY_ROTATION)
		expect(@station.spins_per_week[@song2.id]).to eq(PL::MEDIUM_ROTATION)
		expect(@station.spins_per_week[@song3.id]).to eq(PL::LIGHT_ROTATION)
		expect(@station.created_at).to eq(Time.new(1970))
		expect(@station.updated_at).to eq(Time.new(1970, 1, 2))
	end

	it "allows editing of the spins_per_week hash" do
		@station.spins_per_week[5] = 10
		expect(@station.spins_per_week[5]).to eq(10)
	end

end