require 'spec_helper'

describe 'commercial_block_factory' do
  before(:each) do
    @station = PL.db.create_station({ user_id: 1,
                                      secs_of_commercial_per_hour: 180 })
    @schedule = PL.db.create_schedule({ station_id: @station.id })
    @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
    @commercial_block_factory = PL::CommercialBlockFactory.new
  end

  it 'returns a commercial block of the correct length' do
    new_cb = @commercial_block_factory.construct_block(@station)
    expect(new_cb.duration).to eq(180*1000)
    expect(new_cb.station_id).to eq(@station.id)
  end
end