require 'spec_helper'
require 'timecop'

describe 'GetCommercialBlockForBroadcast' do
  it 'calls bullshit of the station is not found' do
    result = PL::GetCommercialBlockForBroadcast.run({ station_id: 9999,
                      start_time: Time.local(2014,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  describe 'More GetSpinByCurrentPosition' do
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

    it 'calls bullshit if commercial_block has not been scheduled yet' do
      Timecop.travel(Time.local(2014,5,10, 10,30))
      result = PL::GetCommercialBlockForBroadcast.run({ station_id: @station.id,
                                                        current_position: 7000 })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:commercial_not_scheduled_yet)
    end

    it 'calls bullshit if the commercial_block is not scheduled for that block' do
      Timecop.travel(Time.local(2014,5,10, 10,30))
      result = PL::GetCommercialBlockForBroadcast.run({ station_id: @station.id,
                                                        current_position: 1 })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_commercial_at_current_position)
    end

    it 'gets a commercial_block for broadcast' do
      Timecop.travel(Time.local(2014,5,10, 10,56))
      result = PL::GetCommercialBlockForBroadcast.run({ station_id: @station.id,
                                    current_position: 428 })
      expect(result.success?).to eq(true)
      expect(result.commercial_block.airtime.to_s).to eq('2014-05-10 11:02:20 -0500')
    end

    after(:all) do
      Timecop.return
    end
  end
end