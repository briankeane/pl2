require 'spec_helper'

describe 'DeleteSpinFrequency' do
  before(:each) do
    @station = PL.db.create_station({ user_id: 1 })
    @heavy_rl = []
    @medium_rl = []
    @light_rl = []
    PL::MIN_HEAVY_COUNT.times do |i|
      @heavy_rl << PL.db.create_spin_frequency({ song_id: i+1, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    end
    PL::MIN_MEDIUM_COUNT.times do |i|
      @medium_rl << PL.db.create_spin_frequency({ song_id: i+101, station_id: @station.id, spins_per_week: PL::MEDIUM_ROTATION })
    end
    PL::MIN_LIGHT_COUNT.times do |i|
      @light_rl << PL.db.create_spin_frequency({ song_id: i+201, station_id: @station.id, spins_per_week: PL::LIGHT_ROTATION })
    end
  end

  it "calls bullshit if it can't find the station" do
    result = PL::DeleteSpinFrequency.run({ song_id: 1, station_id: 9999, spins_per_week: PL::HEAVY_ROTATION })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it "calls bullshit if the song is not already in rotation" do
    PL.db.create_spin_frequency({ song_id: 9999, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    result = PL::DeleteSpinFrequency.run({ song_id: 10000, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:spin_frequency_not_found)
  end

  it 'can delete a spin frequency' do
    PL.db.create_spin_frequency({ song_id: 9999, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
    result = PL::DeleteSpinFrequency.run({ song_id: 9999, station_id: @station.id })
    expect(result.success?).to eq(true)
    expect(PL.db.get_station(@station.id).spins_per_week[9999]).to eq(nil)
    expect(result.station.id).to eq(@station.id)
  end

  it 'refuses to delete if already at minimum' do
    result = PL::DeleteSpinFrequency.run({ song_id: 1, station_id: @station.id })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:minimum_spin_frequencies_met)
  end

end