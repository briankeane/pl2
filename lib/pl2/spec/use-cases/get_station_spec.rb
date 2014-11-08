require 'spec_helper'

describe 'GetStation' do
  it 'calls bullshit if the station does not exist' do
    result = PL::GetStation.run(999)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end
  it 'gets a station' do
    station = PL.db.create_station({ user_id: 1 })
    result = PL::GetStation.run(station.id)
    expect(result.success?).to eq(true)
    expect(result.station.id).to eq(station.id)
    expect(result.station.user_id).to eq(1)
  end
end