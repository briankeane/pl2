require 'spec_helper'
require 'Timecop'
require 'pry-debugger'

describe "RemoveSpin" do

  before(:each) do
    PL.db.clear_everything
    Timecop.travel(Time.local(2014, 5, 9, 10))
    @user = PL.db.create_user({ twitter: 'bob', timezone: 'Central Time (US & Canada)' })
    @station = PL.db.create_station({ user_id: @user.id })
    @schedule = PL.db.create_schedule({ station_id: @station.id })
    @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
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
    @station = PL.db.update_station({ id: @station.id,
                                        spins_per_week: spins_per_week 
                                     })
    @schedule.generate_playlist
  end

  it "calls bullshit if the schedule_id is invalid" do
    result = PL::RemoveSpin.run({ schedule_id: 999,
                                  old_position: 8,
                                  new_position: 7 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:schedule_not_found)
  end

  it "removes a spin" do
    program_before_ids = @schedule.get_program.map { |spin| spin.id }
    result = PL::RemoveSpin.run({ schedule_id: @schedule.id,
                                  current_position: 9 })
    program_after_ids = @schedule.get_program.map { |spin| spin.id }
    expect(result.success?).to eq(true)
    expect(program_before_ids[12]).to eq(program_after_ids[11])  # everything is shifted back one spin
    expect(program_after_ids.include?(program_before_ids[7])).to eq(false)  #removed_spin is gone
    late_program_ids = @schedule.get_program(start_time: Time.new(2014,5,10,3)).map { |spin| spin.id }
    expect(late_program_ids[1]).to eq(program_before_ids[7])  #removed spin has been inserted at 3am  
  end

  after(:each) do
    Timecop.return
  end

end