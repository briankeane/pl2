require 'spec_helper'
require 'Timecop'
require 'pry-byebug'

describe 'a station' do
  before(:each) do
    PL.db.clear_everything
    @user = PL.db.create_user({ twitter: 'bob' })
    @song1 = PL.db.create_song({ title: '1' })
    @song2 = PL.db.create_song({ title: '2' })
    @song3 = PL.db.create_song({ title: '3' })
    @station = PL::Station.new({ id: 1,
       secs_of_commercial_per_hour: 3,
                           user_id: @user.id,
                             spins_per_week: {  @song1.id => PL::HEAVY_ROTATION,
                                                @song2.id => PL::MEDIUM_ROTATION, 
                                                @song3.id => PL::LIGHT_ROTATION },
                             created_at: Time.new(1970),
                             updated_at: Time.new(1970, 1, 2) })
  end

  it 'is created with an id, secs_of_commercial_per_hour, user_id, and spins_per_week array' do
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

  it "allows editing of the spins_per_week hash" do
    @station.spins_per_week[5] = 10
    expect(@station.spins_per_week[5]).to eq(10)
  end
  
  it 'can create a sample array' do
    sample_array = @station.create_sample_array
    expect(sample_array.size > 20).to eq(true)
  end



  after (:all) do
    Timecop.return
  end

  describe 'make_log_current' do
    before (:each) do
      
      @station = PL.db.create_station({ user_id: 1, secs_of_commercial_per_hour: 300 })
      @station = PL.db.create_station({ station_id: @station.id })
      PL.db.update_station({ id: @station.id, station_id: @station.id })
      @song = PL.db.create_song({ duration: 180000 })
      @spin1 = PL.db.create_spin({ current_position: 15,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,
                                      airtime: Time.new(2014, 4, 15, 11, 25) 
                                      })
      @spin2 = PL.db.create_spin({ current_position: 16,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,                                     
                                      airtime: Time.new(2014, 4, 15, 11, 28) 
                                      })
      @spin3 = PL.db.create_spin({ current_position: 17,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,                                     
                                      airtime: Time.new(2014, 4, 15, 11, 31) 
                                      })
      @spin4 = PL.db.create_spin({ current_position: 18,
                                      station_id: @station.id,
                                      audio_block_id: @song.id,
                                      airtime: Time.new(2014, 4, 15, 11, 34) 
                                      })
      @log = PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 14,
                                      airtime: Time.new(2014, 4, 15, 11, 22),
                                      duration: 180000 
                                      })
    end

    it 'gets a commercial block for broadcast' do
      cb = @station.get_commercial_block_for_broadcast(18)
      expect(cb.is_a?(PL::CommercialBlock)).to eq(true)
    end

    it 'returns the same commercial block for 2nd request' do
      cb = @station.get_commercial_block_for_broadcast(18)
      cb2 = @station.get_commercial_block_for_broadcast(18)
      expect(cb.id).to eq(cb2.id)
    end


    it 'gets the average number of listeners' do
      log = []
      10.times do |i|
        log << PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 13 - i,
                                      airtime: Time.new(2014,4,15, 11, (31 - (i*3))),
                                      duration: 180000,
                                      listeners_at_start: 35 + i,
                                      listeners_at_finish: 30 + i, 
                                      })
      end
      Timecop.travel(2014,4,16, 12)
      expect(@station.average_daily_listeners).to eq(31.363636363636363)
      Timecop.travel(2014,4,17, 12)
      expect(@station.average_daily_listeners).to eq(0)
    end

    describe 'just_played' do
      it 'gets the last log entry' do
        expect(@station.just_played.current_position).to eq(14)
      end

      it 'still gets the last log entry' do
        new_log = PL.db.create_log_entry({ station_id: @station.id,
                                            current_position: 999,
                                            airtime: Time.new(2014,4,15,12) })
        expect(@station.just_played.current_position).to eq(999)
      end
    end


    describe 'log_end_time' do
      it 'returns the time the log ends' do
        expect(@station.log_end_time.to_s).to eq('2014-04-15 11:25:00 -0500')
        log2 = PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 14,
                                      airtime: Time.new(2014, 4, 15, 11, 57),
                                      duration: 180000 
                                      })
        expect(@station.log_end_time.localtime.to_s).to eq('2014-04-15 12:00:00 -0500')
      end
    end

    after (:all) do
      Timecop.return
    end
  end
end