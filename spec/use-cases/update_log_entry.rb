require 'spec_helper'

describe 'UpdateLogEntry' do
  it 'calls bullshit if the station is not found' do
    result = PL::UpdateLogEntry.run({ station_id: 5, song_id: 5 })
  end

end