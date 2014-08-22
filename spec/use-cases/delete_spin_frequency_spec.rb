require 'spec_helper'

describe 'DeleteSpinFrequency' do
  before(:each) do
    @station = PL.db.create_station({ user_id: 1 })
    @heavy_rl = PL.db.create_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    @medium_rl = PL.db.create_spin_frequency({ song_id: 2, station_id: @station.id, spins_per_week: PL::MEDIUM_ROTATION })
    @light_rl = PL.db.create_spin_frequency({ song_id: 3, station_id: @station.id, spins_per_week: PL::LIGHT_ROTATION })
  end

  it 'can delete a spin frequency' do
    result = PL::DeleteSpinFrequency.run({ song_id: 1, station_id: @station.id })
    expect(result.success?).to eq(true)
    expect(PL.db.get_station(@station.id).spins_per_week[1]).to eq(nil)
    expect(result.station.id).to eq(@station.id)
  end

end