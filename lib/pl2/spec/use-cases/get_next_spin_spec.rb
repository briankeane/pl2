require 'spec_helper'
require 'timecop'

describe 'GetNextSpin' do
    it 'calls bullshit if station is not found' do
        result = PL::GetNextSpin.run(9999)
        expect(result.success?).to eq(false)
        expect(result.error).to eq(:schedule_not_found)
    end

  it 'grabs the next spin' do
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
    result = PL::GetNextSpin.run(@station.id)
    expect(result.success?).to eq(true)
    expect(result.next_spin.current_position).to eq(2)
  end
end