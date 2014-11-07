require 'spec_helper'

describe 'UpdateStation' do
  it 'calls bullshit if the station is not found' do
    result = PL::UpdateStation.run({ id: 99999,
                          secs_of_commercial_per_hour: 1 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it 'updates the station' do
    station = PL.db.create_station({ user_id: 1,
                                secs_of_commercial_per_hour:100,
                               })
    result = PL::UpdateStation.run({ id: station.id,
                                secs_of_commercial_per_hour: 99 })
    expect(result.success?).to eq(true)
    expect(result.station.id).to eq(station.id)
    expect(result.station.secs_of_commercial_per_hour).to eq(99)
  end
end
