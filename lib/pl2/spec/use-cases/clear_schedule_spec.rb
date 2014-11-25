require 'spec_helper'
require 'timecop'

describe 'ClearSchedule' do
  before (:each) do
    Timecop.travel(Time.local(2014, 5, 9, 10))
    @user = PL.db.create_user({ twitter: "Bob" })
    @songs = []
    86.times do |i|
      @songs << PL.db.create_song({ title: "#{i} title", artist: "#{i} artist", album: "#{i} album", duration: 190000 })
    end

    # build spins_per_week
    heavy = @songs[0..30]
    medium = @songs[31..65]
    light = @songs[66..85]

    spins_per_week = {}
    heavy.each { |song| spins_per_week[song.id] = PL::HEAVY_ROTATION }
    medium.each { |song| spins_per_week[song.id] = PL::MEDIUM_ROTATION }
    light.each { |song| spins_per_week[song.id] = PL::LIGHT_ROTATION }
    @station = PL.db.create_station({ user_id: @user.id, 
                                        spins_per_week: spins_per_week 
                                     })
    @schedule = PL.db.create_schedule({ station_id: @station.id })
    @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
    @schedule.generate_playlist
  end

  it 'calls bullshit if the schedule does not exist' do
    result = PL::ClearSchedule.run(9999999)
    expect(result.error).to eq(:schedule_not_found)
  end

  it 'clears a schedule' do
    result = PL::ClearSchedule.run(@schedule.id)
    expect(result.success?).to eq(true)
    expect(PL.db.get_full_playlist(@schedule.id).size).to eq(0)
    expect(@schedule.now_playing).to_not be_nil
  end

  after(:all) do
    Timecop.return
  end

end