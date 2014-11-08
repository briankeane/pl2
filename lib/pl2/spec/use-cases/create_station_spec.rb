require 'spec_helper'

describe 'CreateStation' do
  before(:each) do
    @songs = []
    30.times do |i| 
      @songs << PL.db.create_song({ artist: i })
    end
    @spins_per_week = {}
    heavy = @songs[0..9]
    medium = @songs[10..19]
    light = @songs[20..29]
    heavy.each { |song| @spins_per_week[song.id] = PL::HEAVY_ROTATION }
    medium.each { |song| @spins_per_week[song.id] = PL::MEDIUM_ROTATION }
    light.each { |song| @spins_per_week[song.id] = PL::LIGHT_ROTATION }
  end

  it 'calls bullshit if the user is not found' do
    result = PL::CreateStation.run({ user_id: 1, spins_per_week: @spins_per_week })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'calls bullshit if the user already has a station' do
    user = PL.db.create_user({ twitter: 'bob' })
    station = PL.db.create_station({ user_id: user.id })
    result = PL::CreateStation.run({ user_id: user.id, spins_per_week: @spins_per_week })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_already_exists)
    expect(result.station.id).to eq(station.id)
  end

  it 'creates a station' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id, spins_per_week: @spins_per_week })
    expect(result.success?).to eq(true)
    expect(result.station.id).to be_a(Fixnum)
    expect(result.station.spins_per_week.size).to eq(30)
    expect(result.station.user_id).to eq(user.id)
  end

  it 'also creates a schedule and connects them' do
    user = PL.db.create_user({ twitter: 'bob' })
    result = PL::CreateStation.run({ user_id: user.id, spins_per_week: @spins_per_week })
    expect(result.success?).to eq(true)
    expect(PL.db.get_schedule(result.station.schedule_id)).to be_a(PL::Schedule)
  end


end