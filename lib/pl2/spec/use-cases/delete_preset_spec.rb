require 'spec_helper'

describe 'CreatePreset' do

  it 'calls bullshit if the preset does not exist' do
    result = PL::DeletePreset.run({ station_id: 999,
                                      user_id: 555 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:preset_not_found)
  end

  it 'deletes a preset' do
    PL.db.create_preset({ user_id: 1, station_id: 2 })
    PL.db.create_preset({ user_id: 1, station_id: 3 })
    PL.db.create_preset({ user_id: 1, station_id: 4 })

    result = PL::DeletePreset.run({ station_id: 4,
                                          user_id: 1 })
    expect(result.success?).to eq(true)
    expect(result.presets).to eq([2,3])
    expect(PL.db.get_presets(1)).to eq([2,3])
  end

end