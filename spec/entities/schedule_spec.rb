require 'spec_helper'
require 'timecop'

describe 'schedule' do

  before(:each) do
    @user = PL.db.create_user({ twitter: 'bob', timezone: 'Central Time (US & Canada)' })
    @station = PL.db.create_station({ user_id: @user.id })
    @schedule = PL.db.create_schedule({ station_id: @station.id })
    @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
  end

  it 'is created with an id, station_id' do
    schedule = PL::Schedule.new({ id: 1, station_id: 10 })
    expect(schedule.id).to eq(1)
    expect(schedule.station_id).to eq(10)
  end

  it "can get it's station" do
    expect(@schedule.station.id).to eq(@station.id)
  end

  describe 'generate playlist' do
    before(:each) do
      Timecop.travel(Time.local(2014, 5, 9, 10))
      @user = PL.db.create_user({ twitter: "Bob", password: "password" })
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

    it 'creates a first playlist' do
      generated_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(generated_playlist.size).to eq(5560)
      expect(PL.db.get_full_station_log(@station.id).size).to eq(1)
    end

    after(:all) do
      Timecop.return
    end
  end


  describe 'make_log_current' do
    before (:each) do
      @station = PL.db.create_station({ user_id: 1, secs_of_commercial_per_hour: 300 })
      @song = PL.db.create_song({ duration: 180000 })
      @spin1 = PL.db.create_spin({ current_position: 15,
                                      schedule_id: @schedule.id,
                                      audio_block_id: @song.id,
                                      estimated_airtime: Time.new(2014, 4, 15, 11, 25) 
                                      })
      @spin2 = PL.db.create_spin({ current_position: 16,
                                      schedule_id: @schedule.id,
                                      audio_block_id: @song.id,                                     
                                      estimated_airtime: Time.new(2014, 4, 15, 11, 28) 
                                      })
      @spin3 = PL.db.create_spin({ current_position: 17,
                                      schedule_id: @schedule.id,
                                      audio_block_id: @song.id,                                     
                                      estimated_airtime: Time.new(2014, 4, 15, 12, 31) 
                                      })
      @spin4 = PL.db.create_spin({ current_position: 18,
                                      schedule_id: @schedule.id,
                                      audio_block_id: @song.id,
                                      estimated_airtime: Time.new(2014, 4, 15, 12, 38) 
                                      })
      @log = PL.db.create_log_entry({ station_id: @station.id,
                                      current_position: 14,
                                      airtime: Time.new(2014, 4, 14, 11, 56),
                                      duration: 180000 
                                      })
    end

    it 'does nothing if the station has been running' do
      Timecop.travel(Time.local(2014, 4, 14, 11, 55))
      @schedule.bring_current
      expect(PL.db.get_log_entry(@log.id).airtime.to_s).to eq(Time.new(2014, 4, 14, 11, 56).to_s)
      expect(PL.db.get_full_playlist(@station.id).size).to eq(4)
    end

    it 'updates if the station has been off' do
      Timecop.travel(Time.local(2014, 4, 14, 11, 59))
      @schedule.bring_current
      log = PL.db.get_full_station_log(@station.id)
      expect(log[1].airtime.localtime.to_s).to eq(Time.local(2014, 4, 14, 11, 56).to_s)
      expect(log[0].airtime.localtime.to_s).to eq(Time.local(2014, 4, 14, 11, 59).to_s)
      expect(log.size).to eq(2)
      expect(log[0].current_position).to eq(15)
      expect(log[1].current_position).to eq(14)
      expect(log[0].listeners_at_finish).to be_nil
      expect(log[1].listeners_at_finish).to eq(0)
    end

    it 'accounts for commercials properly' do
      Timecop.travel(Time.local(2014,4,14, 12,9))
      @schedule.bring_current
      log = PL.db.get_full_station_log(@station.id)

      expect(log.size).to eq(5)
      expect(log[2].duration).to eq(150000)
    end

    it "doesn't mess up when 1st log is a commercial" do
      Timecop.travel(Time.local(2014,4,14, 12))
      @schedule.bring_current
      Timecop.travel(Time.local(2014,4,14, 12,9))
      @schedule.bring_current
      log = PL.db.get_full_station_log(@station.id)

      expect(log.size).to eq(5)
      expect(log[2].duration).to eq(150000)
    end
  end

  describe 'adjust_playlist' do
    before(:each) do
      song = PL.db.create_song({ duration: 180000 })
      @station = PL.db.create_station({ user_id: 1, secs_of_commercial_per_hour: 300 })
      @schedule = PL.db.create_schedule({ station_id: @station.id })
      @spins = []
      30.times_with_index do |i|
        @spins << Spin.new({ audio_block_id: song.id,
                              schedule_id: @schedule.id })
      end
    end

    xit 'inserts commercials correctly' do
    end

    xit 'leads off with a commercial properly' do
    end

  end

end
