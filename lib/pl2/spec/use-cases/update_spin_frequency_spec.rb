require 'spec_helper'

describe 'UpdateSpinFrequency' do
  before(:each) do
    @station = PL.db.create_station({ user_id: 1 })
    @song1 = PL.db.create_song({})
    @song2 = PL.db.create_song({})
    @song3 = PL.db.create_song({})

    @heavy_rl = PL.db.create_spin_frequency({ song_id: @song1.id, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    @medium_rl = PL.db.create_spin_frequency({ song_id: @song2.id, station_id: @station.id, spins_per_week: PL::MEDIUM_ROTATION })
    @light_rl = PL.db.create_spin_frequency({ song_id: @song3.id, station_id: @station.id, spins_per_week: PL::LIGHT_ROTATION })
  end

  it 'calls bullshit when the station is not found' do
    result = PL::UpdateSpinFrequency.run({ song_id: @song1.id, station_id: 999, spins_per_week: 1 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it 'calls bullshit when the song is not found' do
    result = PL::UpdateSpinFrequency.run({ song_id: 999, station_id: @station.id, spins_per_week: 1 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:song_not_found)
  end

  it 'can update a spin frequency' do
    result = PL::UpdateSpinFrequency.run({ song_id: @song1.id, station_id: @station.id, spins_per_week: 1 })
    expect(result.success?).to eq(true)
    expect(PL.db.get_station(@station.id).spins_per_week[@song1.id]).to eq(1)
    expect(result.station.id).to eq(@station.id)
  end
end
