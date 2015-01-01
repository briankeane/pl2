require 'spec_helper'
require 'timecop'
require 'pry-byebug'

describe 'GetProgramForBroadcast' do
  it 'calls bullshit of the station is not found' do
    result = PL::GetProgramForBroadcast.run({ station_id: 9999,
                      start_time: Time.local(2014,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  describe 'More GetProgramForBroadcast' do
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
      @station.generate_playlist
    end

    it 'gets a playlist' do
      result = PL::GetProgramForBroadcast.run({ station_id: @station.id })
      expect(result.success?).to eq(true)
      expect(result.program.size).to eq(3)
      expect(result.program[0].id).to eq(@station.now_playing.id)
    end

    it 'gets a playlist if now_playing is a commercial' do
      Timecop.travel(Time.local(2014,5,9, 11))
      result = PL::GetProgramForBroadcast.run({ station_id: @station.id })
      expect(result.success?).to eq(true)
      expect(result.program[0]).to be_a(PL::CommercialBlock)
    end

    it 'returns 4 spins if the 3rd one is a commercial_block' do
      Timecop.travel(Time.local(2014,5,9, 10,53))
      result = PL::GetProgramForBroadcast.run({ station_id: @station.id })
      binding.pry
      expect(result.success?).to eq(true)
      expect(result.program.size).to eq(4)
    end

    after(:all) do
      Timecop.return
    end
  end
end