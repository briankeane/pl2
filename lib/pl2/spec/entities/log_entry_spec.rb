require 'spec_helper'
require 'pry-byebug'
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
                              type: 'test',
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
    expect(@log.type).to eq('test')
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

  it 'calculates airtime_in_ms' do
    expect(@log.airtime_in_ms).to eq(Time.new(1983,4,15, 18).to_f*1000)
  end

  it 'calculates listeners_at_start and listeners_at_finish if necessary' do
    log = PL.db.create_log_entry({ station_id: 4,
                                    current_position: 76,
                                    audio_block_id: @song.id,
                                    airtime: Time.new(1983,4,15, 18),
                                    duration: 180000 })
    PL.db.create_listening_session({ station_id: 4,
                                      user_id: 1,
                                      starting_current_position: 75,
                                      ending_current_position: 76,
                                      start_time: Time.new(1983,4,15, 17, 59),
                                      end_time: Time.new(1983,4,15, 18,5) })
    PL.db.create_listening_session({ station_id: 4,
                                      user_id: 2,
                                      starting_current_position: 76,
                                      ending_current_position: 80,
                                      start_time: Time.new(1983,4,15, 18,2),
                                      end_time: Time.new(1983,4,15, 18,10) })
    expect(log.listeners_at_start).to eq(1)
    expect(log.listeners_at_finish).to eq(2)
  end

  it 'creates a hash of itself' do
    hash = @log.to_hash
    expect(hash[:station_id]).to eq(4)
    expect(hash[:current_position]).to eq(76)
    expect(hash[:audio_block_id]).to eq(@song.id)
    expect(hash[:airtime].to_s).to eq(Time.new(1983, 4, 15, 18).to_s)
    expect(hash[:listeners_at_start]).to eq(55)
    expect(hash[:listeners_at_finish]).to eq(57)
    expect(hash[:duration]).to eq(1000)
    expect(hash[:type]).to eq('test')
    expect(hash[:estimated_end_time]).to eq(@log.estimated_end_time)
    expect(hash[:audio_block][:id]).to eq(@song.id)
    expect(hash[:audio_block][:title]).to eq('song')
    expect(hash[:airtime_in_ms]).to eq(@log.airtime_in_ms)
    expect(hash[:commercials_follow?]).to eq(@log.commercials_follow?)
  end
end