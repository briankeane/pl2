require 'spec_helper'

describe 'a log entry' do
  before(:each) do
    @song = PL.db.create_song({ title: 'song', duration: 1000 })
    @log = PL::LogEntry.new({ id: 1,
                              station_id: 4,
                              current_position: 76,
                              audio_block_id: @song.id,
                              airtime: Time.new(1983, 4, 15, 18),
                              listeners_at_start: 55,
                              listeners_at_finish: 57,
                              duration: 1000 })
  end

  it 'can be created' do
    expect(@log.station_id).to eq(4)
    expect(@log.current_position).to eq(76)
    expect(@log.audio_block_id).to eq(@song.id)
    expect(@log.airtime.to_s).to eq(Time.new(1983, 4, 15, 18).to_s)
    expect(@log.listeners_at_start).to eq(55)
    expect(@log.listeners_at_finish).to eq(57)
    expect(@log.duration).to eq(1000)
  end

  it 'calculates estimated_end_time' do
    expect(@log.estimated_end_time.to_s).to eq(Time.new(1983,4,15, 18,00,01).to_s)
  end

  it 'tells if commercials follow' do
    song = PL.db.create_song({ duration: 20000 })
    log_entry = PL::LogEntry.new({ audio_block_id: song.id, airtime: Time.new(1983,4,15, 12,05), duration: 20000 })
    expect(log_entry.commercials_follow?).to eq(false)
    log_entry.airtime = Time.new(1983,4,15, 12,59,59)
    expect(log_entry.commercials_follow?).to eq(true)
  end
end