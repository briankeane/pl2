require 'spec_helper'
require 'Timecop'

describe "MoveSpin" do

  before(:each) do
    @user = PL.db.create_user ({ twitter: "bob", password: "password", email: "bob@bob.com" })
    @station = PL.db.create_station({ user_id: @user.id })
    @schedule = PL.db.create_schedule({ station_id: @station.id })
    @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
    @song1 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song2 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song3 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song4 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song5 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song6 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })

    @spin1 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song1.id, current_position: 5 })
    @spin2 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song2.id, current_position: 6 })
    @spin3 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song3.id, current_position: 7 })
    @spin4 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song4.id, current_position: 8 })
    @spin5 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song5.id, current_position: 9 })
    @spin6 = PL.db.create_spin({ schedule_id: @schedule.id, audio_block_id: @song6.id, current_position: 10 })
    @schedule.last_accurate_current_position = 10
  end

  it "calls bullshit if the schedule_id is invalid" do
    result = PL::MoveSpin.run({ schedule_id: 999,
                                  old_position: 8,
                                  new_position: 7 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:schedule_not_found)
  end

  it "calls bullshit if old_position is invalid" do
    session_id = PL.db.create_session(@user.id)
    result = PL::MoveSpin.run({ schedule_id: @schedule.id,
                                  old_position: 999,
                                  new_position: 7 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:invalid_old_position)
  end

  it "calls bullshit if new_position is invalid" do
    session_id = PL.db.create_session(@user.id)
    result = PL::MoveSpin.run({ schedule_id: @schedule.id,
                                  old_position: 7,
                                  new_position: 999 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:invalid_new_position)
  end

  it "moves a spin" do
    session_id = PL.db.create_session(@user.id)
    result = PL::MoveSpin.run({ schedule_id: @schedule.id,
                                  old_position: 7,
                                  new_position: 9 })
    expect(result.success?).to eq(true)
    expect(PL.db.get_full_playlist(@schedule.id).map { |spin| spin.audio_block.id }).to eq([@song1.id, @song2.id, @song4.id,@song5.id,@song3.id,@song6.id])
  end

  it 'rearranges the last_accurate_current_position after moving the spin' do
    session_id = PL.db.create_session(@user.id)
    result = PL::MoveSpin.run({ schedule_id: @schedule.id,
                                  old_position: 7,
                                  new_position: 9 })
    expect(result.success?).to eq(true)
    expect(@schedule.last_accurate_current_position).to eq(6)
  end

end