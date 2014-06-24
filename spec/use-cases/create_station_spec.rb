require 'spec_helper'

describe 'CreateStation' do

  it 'calls bullshit if the user is not found' do
    result = PL::CreateStation.run({ user_id: 1,
                                   heavy: [1,2,3,4,5,6,7,8,9,10],
                                   medium: [11,12,13,14,15,16,17,18,19,20],
                                   light: [21,22,23,24,25,26,27,28,29,30] 
                                    })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'calls bullshit if the user already has a station' do
    user = PL.db.create_user({ twitter: 'bob' })
    station = PL.db.create_station({ user_id: user.id })
    result = PL::CreateStation.run({ user_id: user.id,
                                   heavy: [1,2,3,4,5,6,7,8,9,10],
                                   medium: [11,12,13,14,15,16,17,18,19,20],
                                   light: [21,22,23,24,25,26,27,28,29,30] 
                                    })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_already_exists)
    expect(result.station.id).to eq(station.id)
  end

  it 'calls bullshit if the heavy songlist is not long enough' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id,
                                   heavy: [1,2,3,4,5,6,7,8,9],
                                   medium: [11,12,13,14,15,16,17,18,19,20],
                                   light: [21,22,23,24,25,26,27,28,29,30] 
                                    })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:not_enough_heavy_rotation_songs)
    expect(result.minimum_required).to eq(PL::MIN_HEAVY_COUNT)
  end

  it 'calls bullshit if the medium songlist is not long enough' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id,
                                   heavy: [1,2,3,4,5,6,7,8,9,10],
                                   medium: [11,12,13,14,15,16,17,18,19],
                                   light: [21,22,23,24,25,26,27,28,29,30] 
                                    })  
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:not_enough_medium_rotation_songs)
    expect(result.minimum_required).to eq(PL::MIN_MEDIUM_COUNT)
  end

  it 'calls bullshit if the light songlist is not long enough' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id,
                                   heavy: [1,2,3,4,5,6,7,8,9,10],
                                   medium: [11,12,13,14,15,16,17,18,19,20],
                                   light: [21,22,23] 
                                    })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:not_enough_light_rotation_songs)
    expect(result.minimum_required).to eq(PL::MIN_LIGHT_COUNT)
  end

  it 'creates a station' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id,
                                   heavy: [1,2,3,4,5,6,7,8,9,10],
                                   medium: [11,12,13,14,15,16,17,18,19,20],
                                   light: [21,22,23,24,25,26,27] 
                                    })
    expect(result.success?).to eq(true)
    expect(result.station.id).to be_a(Fixnum)
    expect(result.station.spins_per_week.size).to eq(27)
    expect(result.station.user_id).to eq(user.id)
  end

end