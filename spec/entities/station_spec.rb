require 'spec_helper'
require 'Timecop'

describe 'a station' do
  before(:each) do
    PL.db.clear_everything
    @user = PL.db.create_user({ twitter: 'bob' })
    @song1 = PL::Song.new({ id: 1 })
    @song2 = PL::Song.new({ id: 2 })
    @song3 = PL::Song.new({ id: 3 })
    @station = PL::Station.new({ id: 1,
       secs_of_commercial_per_hour: 3,
                           user_id: @user.id,
                             spins_per_week: {  @song1.id => PL::HEAVY_ROTATION,
                                                @song2.id => PL::MEDIUM_ROTATION, 
                                                @song3.id => PL::LIGHT_ROTATION },
                             created_at: Time.new(1970),
                             updated_at: Time.new(1970, 1, 2) })
  end

  it 'is created with an id, secs_of_commercial_per_hour, user_id, and heavy, medium, and light rotation arrays' do
    expect(@station.id).to eq(1)
    expect(@station.secs_of_commercial_per_hour).to eq(3)
    expect(@station.user_id).to eq(@user.id)
    expect(@station.spins_per_week[@song1.id]).to eq(PL::HEAVY_ROTATION)
    expect(@station.spins_per_week[@song2.id]).to eq(PL::MEDIUM_ROTATION)
    expect(@station.spins_per_week[@song3.id]).to eq(PL::LIGHT_ROTATION)
    expect(@station.created_at).to eq(Time.new(1970))
    expect(@station.updated_at).to eq(Time.new(1970, 1, 2))
  end

  it "can get it's user" do
    expect(@station.user.id).to eq(@station.user_id)
  end

  it "can get it's schedule" do
    expect(@station.schedule.id).to eq(@station.schedule_id)
  end

  it "allows editing of the spins_per_week hash" do
    @station.spins_per_week[5] = 10
    expect(@station.spins_per_week[5]).to eq(10)
  end

  describe 'get_program' do
    it 'gets the current program' do
      Timecop.travel(Time.local(2014, 5, 9, 11))
      program = @station.get_program({})
      expect(program.size).to eq(38)
      expect(program.first.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,9, 11,3).to_s)
      expect(program.last.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,9, 12,59,40).to_s)
      expect(program[9]).to be_a(PL::CommercialBlock)
    end

    it 'gets a future program' do
      program = @station.get_program({ start_time: Time.local(2014,5,10, 11,20) })
      expect(program.size).to eq(41)
      expect(program.first.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 11,18).to_s)
      expect(program.last.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 13,24).to_s)
    end

    it 'returns an empty array if there is no program scheduled' do
      program = @station.get_program({ start_time: Time.local(2015,1,1) })
      expect(program).to eq([])
    end

    it 'gets variable lengths of time' do
      program = @station.get_program({ start_time: Time.local(2014,5,10, 4,20),
                                        end_time: Time.local(2014,5,10, 11,20) })
      expect(program.size).to eq(137)
      expect(program.first.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 4,16).to_s)
      expect(program.last.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 11,24,20).to_s)
    end

    it 'works if 1st spin is a commercial_block' do
      program = @station.get_program({ start_time: Time.local(2014,5,10, 4,5) })
      expect(program.first.estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 4,0,20).to_s)
      expect(program.first).to be_a(PL::CommercialBlock)
    end

    it 'works if previous spin was a commercial_block' do
      program = @station.get_program({ start_time: Time.local(2014,5,10, 4,6) })
      expect(program[1].estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 4,3,20).to_s)
      expect(program[1]).to be_a(PL::Spin)
      expect(program[0]).to be_a(PL::CommercialBlock)
      expect(program[0].estimated_airtime.localtime.to_s).to eq(Time.local(2014,5,10, 4,0,20).to_s)
    end

    it 'puts commercial blocks in the right place' do
      program = @station.get_program({ start_time: Time.local(2014, 5, 9, 10),
                                          end_time: Time.local(2014, 5, 9, 15) })

      expect(program[9]).to be_a(PL::CommercialBlock)
      expect(program[18]).to be_a(PL::CommercialBlock)
      expect(program[28]).to be_a(PL::CommercialBlock)
    end
  end

  describe 'offset' do
    it 'returns the proper station offset' do
      new_spin = PL.db.create_spin({ station_id: @station.id,
                    audio_block_id: @songs[0].id,
                    current_position: 5562 })
      expect(@station.offset.round).to eq(-370.0)

      PL.db.delete_spin(new_spin.id)
      expect(@station.offset.round).to eq(0)
    end
end

  after (:all) do
    Timecop.return
  end

  describe 'make_log_current' do
    before (:each) do
      @station = PL.db.create_station({ user_id: 1, secs_of_commercial_per_hour: 300 })
      @song = PL.db.create_song({ duration: 180000 })
      @spin1 = PL.db.create_spin({ current_position: 15,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,
                                      estimated_airtime: Time.new(2014, 4, 15, 11, 25) 
                                      })
      @spin2 = PL.db.create_spin({ current_position: 16,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,                                     
                                      estimated_airtime: Time.new(2014, 4, 15, 11, 28) 
                                      })
      @spin3 = PL.db.create_spin({ current_position: 17,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,                                     
                                      estimated_airtime: Time.new(2014, 4, 15, 12, 31) 
                                      })
      @spin4 = PL.db.create_spin({ current_position: 18,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,
                                      estimated_airtime: Time.new(2014, 4, 15, 12, 38) 
                                      })
      @log = PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 14,
                                      airtime: Time.new(2014, 4, 14, 11, 56),
                                      duration: 180000 
                                      })
    end

    describe 'just_played' do
      it 'gets the last log entry' do
        expect(@station.just_played.current_position).to eq(14)
      end

      it 'still gets the last log entry' do
        new_log = PL.db.create_log_entry({ station_id: @station.id,
                                            current_position: 999 })
        expect(@station.just_played.current_position).to eq(999)
      end
    end


    describe 'log_end_time' do
      it 'returns the time the log ends' do
        expect(@station.log_end_time.to_s).to eq('2014-04-14 11:59:00 -0500')
        log2 = PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 14,
                                      airtime: Time.new(2014, 4, 14, 11, 57),
                                      duration: 180000 
                                      })
        expect(@station.log_end_time.localtime.to_s).to eq('2014-04-14 12:00:00 -0500')
      end
    end

    after (:all) do
      Timecop.return
    end
  end
end