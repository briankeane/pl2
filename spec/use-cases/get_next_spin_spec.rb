require 'spec_helper'
require 'timecop'

describe 'GetNextSpin' do
	it 'calls bullshit if station is not found' do
		result = PL::GetNextSpin.run(9999)
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:station_not_found)
	end

  it 'grabs the next spin' do
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

    result = PL::GetNextSpin.run(@station.id)
    expect(result.success?).to eq(true)
    expect(result.next_spin.current_position).to eq(2)

  end

end