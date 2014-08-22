require 'spec_helper'

describe 'CreateSpinFrequency' do
  it 'calls bullshit if the station does not exist' do
    song = PL.db.create_song({ artist: 'Brian Keane'})
    result = PL::CreateSpinFrequency.run({ station_id: 999,
                                          song_id: song.id,
                                          spins_per_week: 10 
                                          })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it 'calls bullshit if the song does not exist' do
    station = PL.db.create_station({ user_id: 1 })
    result = PL::CreateSpinFrequency.run({ station_id: station.id,
                                          song_id: 999,
                                          spins_per_week: 10 
                                          })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:song_not_found)
  end

  it 'creates a spin frequency' do
    station = PL.db.create_station({ user_id: 1 })
    song = PL.db.create_song({ artist: 'Brian Keane'})
    result = PL::CreateSpinFrequency.run({ station_id: station.id,
                                          song_id: song.id,
                                          spins_per_week: 10 
                                          })
    expect(result.success?).to eq(true)
    expect(result.station.spins_per_week[song.id]).to eq(10)
  end

end