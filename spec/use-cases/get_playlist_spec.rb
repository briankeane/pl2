require 'spec_helper'
require 'timecop'

describe 'GetProgram' do
  it 'calls bullshit of the station is not found' do
    result = PL::GetProgram.run({ station_id: 9999,
                      start_time: Time.local(2014,10,10, 10,30) })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  describe 'More GetProgram' do
    before (:each) do
      Timecop.travel(Time.local(2014, 5, 9, 10))
      @user = PL.db.create_user({ twitter: "Bob", password: "password" })
      @songs = []
      86.times do |i|
        @songs << PL.db.create_song({ title: "#{i} title", artist: "#{i} artist", album: "#{i} album", duration: 190000 })
      end

      @station = PL.db.create_station({ user_id: @user.id, 
                                          heavy: (@songs[0..30].map { |x| x.id }),
                                          medium: (@songs[31..65].map { |x| x.id }),
                                          light: (@songs[65..85].map { |x| x.id }) 
                                          })
      @station.generate_playlist
    end

    it 'calls bullshit if requested time does not exist' do
      Timecop.travel(Time.local(2014,1,1, 10,30))
      result = PL::GetProgram.run({ station_id: @station.id,
                        start_time: Time.local(2015,10,10, 10,30) })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_playlist_for_requested_time)
      
      result = PL::GetProgram.run({ station_id: @station.id,
                                start_time: Time.local(2011) })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_playlist_for_requested_time)
    end

    it 'gets a playlist' do
      result = PL::GetProgram.run({ station_id: @station.id,
                                    start_time: Time.local(2014,5,12) })
      expect(result.success?).to eq(true)
      expect(result.program.size).to eq(40)
    end

    after(:all) do
      Timecop.return
    end
  end
end