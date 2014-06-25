require 'spec_helper'

describe 'GetRecentLogEntries' do
	it 'calls bullshit if station not found' do
		result = PL::GetRecentLogEntries.run({ station_id: 1, count: 10 })
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:station_not_found)
	end

	it 'gets the recent log entries' do
    @log_entries = []
    @station = PL.db.create_station({ user_id: 1 })
    30.times do |i|
      @log_entries << PL.db.create_log_entry({station_id: @station.id,
                                       current_position: 76 + i,
                                       audio_block_id: 375 + i,
                                       airtime: Time.new(1983, 4, 15, 18) + (i*360),
                                       listeners_at_start: 55 + i,
                                       listeners_at_finish: 57 + i,
                                       duration: 500
                                       })
    end

    result = PL::GetRecentLogEntries.run({ station_id: @station.id, count: 15 })
    expect(result.success?).to eq(true)
    expect(result.log_entries.size).to eq(15)
    expect(result.log_entries[0].current_position).to eq(105)
    expect(result.log_entries[14].current_position).to eq(91)
	end
end