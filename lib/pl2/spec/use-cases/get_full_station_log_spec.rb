require 'spec_helper'

describe 'GetFullStationLog' do
	it 'calls bullshit if the station is not found' do
		result = PL::GetFullStationLog.run(5)
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:station_not_found)
	end

	it 'gets a full station log' do
		station = PL.db.create_station({ user_id: 1 })
    log_entries = []
    30.times do |i|
      log_entries << PL.db.create_log_entry({station_id: station.id,
                                       current_position: 76 + i,
                                       audio_block_id: 375 + i,
                                       airtime: Time.new(1983, 4, 15, 18) + (i*360),
                                       listeners_at_start: 55 + i,
                                       listeners_at_finish: 57 + i,
                                       duration: 500
                                       })
    end

		result = PL::GetFullStationLog.run(station.id)
		expect(result.log.size).to eq(30)
    expect(result.log[0].current_position).to eq(105)
    expect(result.log[29].current_position).to eq(76)
	end
end