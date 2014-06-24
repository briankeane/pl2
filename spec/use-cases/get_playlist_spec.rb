require 'spec_helper'
require 'timecop'

describe 'GetPlaylist' do
  it 'calls bullshit of the station is not found' do
    result = PL::GetPlaylist.run({ station_id: 9999,
                      start_time: Time.local(2014,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  xit 'calls bullshit if requested time does not exist' do
    Timecop.travel(Time.local(2014,10,10, 10,30))
    station = PL.db.create_station({ user_id: 1 })
    result = PL::GetPlaylist.run({ station_id: station.id,
                      start_time: Time.local(2015,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_playlist_for_requested_time)
    Timecop.return
  end

  xit 'gets a playlist' do
  end
end