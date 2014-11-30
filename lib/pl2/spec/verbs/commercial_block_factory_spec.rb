require 'spec_helper'

describe 'commercial_block_factory' do
  before(:each) do
    @station = PL.db.create_station({ user_id: 1,
                                      secs_of_commercial_per_hour: 180,
                                      last_commercial_block_aired: 10 })
    @song = PL.db.create_song({ title: 'bla', duration: 3000 })
    @spin = PL.db.create_spin({ audio_block_id: @song.id, airtime: Time.new(2020,10,11, 10), current_position: 10,
                        station_id: @station.id })
    @commercial_block_factory = PL::CommercialBlockFactory.new
  end

  it 'returns the correct commercial block at the correct length' do
    new_cb = @commercial_block_factory.construct_block({ station: @station, current_position: 10 })
    expect(new_cb.duration).to eq(180*1000)
    expect(new_cb.station_id).to eq(@station.id)
    expect(new_cb.key).to eq('0011_commercial_block.mp3')
  end

  it 'updates the last_commercial_block_aired' do
    new_cb = @commercial_block_factory.construct_block({ station: @station, current_position: 10 })
    expect(@station.last_commercial_block_aired).to eq(11)
    expect(PL.db.get_station(@station.id).last_commercial_block_aired).to eq(11)
  end

  it "resets last_commercial_block if it's at the end of available commercial blocks" do
    @station.last_commercial_block_aired = PL::FINAL_COMMERCIAL_BLOCK
    new_cb = @commercial_block_factory.construct_block({ station: @station, current_position: 10 })
    expect(new_cb.key).to eq('0001_commercial_block.mp3')
    expect(@station.last_commercial_block_aired).to eq(1)
  end

end