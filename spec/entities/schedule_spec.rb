require 'spec_helper'

describe 'schedule' do
  it 'is created with an id, station_id' do
    schedule = PL::Schedule.new({ id: 1, station_id: 10 })
    expect(schedule.id).to eq(1)
    expect(schedule.station_id).to eq(10)
  end

end
