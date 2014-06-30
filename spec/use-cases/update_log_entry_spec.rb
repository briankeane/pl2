require 'spec_helper'

describe 'UpdateLogEntry' do
  it 'calls bullshit if the log_entry is not found' do
    result = PL::UpdateLogEntry.run({ id: 5 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:log_entry_not_found)
  end

  it 'updates a log entry' do
    station = PL.db.create_station({ user_id: 1 })
    entry = PL.db.create_log_entry({ station_id: station.id,
                                      listeners_at_finish: 999 })
    result = PL::UpdateLogEntry.run({ id: entry.id,
                                  listeners_at_finish: 0 })
    expect(result.success?).to eq(true)
    expect(result.entry.listeners_at_finish).to eq(0)
  end
end