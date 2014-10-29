require 'spec_helper'
require 'timecop'

describe 'GetProgram' do
  it 'calls bullshit of the station is not found' do
    result = PL::GetProgram.run({ station_id: 9999,
                      start_time: Time.local(2014,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:schedule_not_found)
  end

  describe 'More GetProgram' do
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

    it 'calls bullshit if requested time does not exist' do
      Timecop.travel(Time.local(2014,1,1, 10,30))
      result = PL::GetProgram.run({ schedule_id: @schedule.id,
                        start_time: Time.local(2015,10,10, 10,30) })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_playlist_for_requested_time)
      
      result = PL::GetProgram.run({ schedule_id: @schedule.id,
                                start_time: Time.local(2011) })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_playlist_for_requested_time)
    end

    it 'gets a playlist' do
      result = PL::GetProgram.run({ schedule_id: @schedule.id,
                                    start_time: Time.local(2014,5,12) })
      expect(result.success?).to eq(true)
      expect(result.program.size).to eq(58)
    end

    after(:all) do
      Timecop.return
    end
  end
end