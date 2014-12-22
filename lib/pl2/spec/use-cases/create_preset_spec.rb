require 'spec_helper'

describe 'CreatePreset' do

  before(:each) do
    @user = PL.db.create_user({ twitter: "Bob" })
    @station = PL.db.create_station({})
  end

  it 'calls bullshit if the station does not exist' do
    result = PL::CreatePreset.run({ station_id: 999,
                                      user_id: @user_id })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it 'calls bullshit if the user does not exist' do
    result = PL::CreatePreset.run({ station_id: @station.id,
                                          user_id: 999 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'creates a preset' do
    result = PL::CreatePreset.run({ station_id: @station.id,
                                          user_id: @user.id })
    expect(result.success?).to eq(true)
    expect(result.presets).to eq([@station.id])
    expect(PL.db.get_presets(@user.id)).to eq([@station.id])
  end

end