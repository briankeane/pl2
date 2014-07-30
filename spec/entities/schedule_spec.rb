require 'spec_helper'
require 'timecop'

describe 'schedule' do
  describe 'crud' do
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
  end

  describe 'generate playlist' do
    before(:each) do
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

    it 'creates a first playlist' do
      generated_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(generated_playlist.size).to eq(5560)
      expect(PL.db.get_full_station_log(@station.id).size).to eq(1)
    end

    after(:all) do
      Timecop.return
    end
  end


  describe 'bring_current' do
    before (:each) do
      @user = PL.db.create_user({ twitter: 'bob' })
      @station = PL.db.create_station({ user_id: @user.id, secs_of_commercial_per_hour: 300 })
      @schedule = PL.db.create_schedule({ station_id: @station.id })
      @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
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
      Timecop.travel(Time.local(2014, 4, 14, 11,56,30))
      @schedule.bring_current
      expect(PL.db.get_log_entry(@log.id).airtime.to_s).to eq(Time.new(2014, 4, 14, 11, 56).to_s)
      expect(PL.db.get_full_playlist(@schedule.id).size).to eq(4)
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
      expect(log[2].audio_block).to be_a(PL::CommercialBlock)
      expect(log[1].airtime.to_s).to eq(Time.local(2014,4,14, 12,04,30).to_s)
    end

    it "doesn't mess up when 1st log is a commercial" do
      Timecop.travel(Time.local(2014,4,14, 12))
      @schedule.bring_current
      Timecop.travel(Time.local(2014,4,14, 12,9))
      @schedule.bring_current
      log = PL.db.get_full_station_log(@station.id)
      expect(log.size).to eq(5)
      expect(log[2].audio_block).to be_a(PL::CommercialBlock)
    end
  end

  describe 'adjust_playlist' do
    before(:each) do
      @song = PL.db.create_song({ duration: 180000 })
      @station = PL.db.create_station({ user_id: 1, secs_of_commercial_per_hour: 300 })
      @schedule = PL.db.create_schedule({ station_id: @station.id })
      @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
      @spins = []
      30.times do |i|
        @spins << PL.db.create_spin({ audio_block_id: @song.id,
                              schedule_id: @schedule.id,
                              current_position: i+1 })
      end
    end

    it 'inserts commercials correctly' do
      spins = @schedule.adjust_playlist({ playlist: @spins,
                                          insert_commercials?: true,
                                          start_time: Time.local(2014,4,14, 12,10) })
      expect(spins[7]).to be_a(PL::CommercialBlock)
      expect(spins[8].estimated_airtime.to_s).to eq(Time.local(2014,4,14, 12,33,30).to_s)
      expect(spins[8]).to be_a(PL::Spin)
      expect(spins[17]).to be_a(PL::CommercialBlock)
    end

    it 'accounts for commercials without inserting them' do
      spins = @schedule.adjust_playlist({ playlist: @spins,
                                          insert_commercials?: false,
                                          start_time: Time.local(2014,4,14, 12,10) })
      expect(spins[7]).to be_a(PL::Spin)
      expect(spins[7].estimated_airtime.to_s).to eq(Time.local(2014,4,14, 12,33,30).to_s)
    end

    it 'leads off with a commercial properly' do
      spins = @schedule.adjust_playlist({ playlist: @spins,
                                          insert_commercials?: true,
                                          lead_with_commercial_block?: true,
                                          start_time: Time.local(2014,4,14, 12,01) })
      expect(spins[0]).to be_a(PL::CommercialBlock)
      expect(spins[1].estimated_airtime.to_s).to eq(Time.local(2014,4,14, 12,3,30).to_s)
      expect(spins[10]).to be_a(PL::CommercialBlock)
      expect(spins[10].estimated_airtime.to_s).to eq(Time.local(2014,4,14, 12,30,30).to_s)
    end

    describe 'update_estimated_airtimes' do
      it 'updates the estimated_airtimes' do
        Timecop.travel(2014,4,15, 12,15)
        PL.db.create_log_entry({ audio_block_id: @song.id,
                                  airtime: Time.local(2014,4,15, 12,14),
                                   station_id: @station.id,
                                   current_position: 0,
                                   duration: 180000
                                })
        @schedule.update_estimated_airtimes
        expect(PL.db.get_full_playlist(@schedule.id).size).to eq(30)
        expect(PL.db.get_full_playlist(@schedule.id)[0].estimated_airtime.to_s).to eq(Time.local(2014,4,15, 12,17).to_s)
      end

      it 'still works if a commercial would be first' do
        Timecop.travel(2014, 4,15, 12,31)
        PL.db.create_log_entry({ audio_block_id: @song.id,
                                  airtime: Time.local(2014,4,15, 12,29),
                                   station_id: @station.id,
                                   current_position: 0,
                                   duration: 180000
                                })
        @schedule.update_estimated_airtimes
        expect(PL.db.get_full_playlist(@schedule.id)[0].estimated_airtime.to_s).to eq(Time.local(2014,4,15, 12,34,30).to_s)
      end
    end
  end

  describe 'playlist functions' do
    before (:each) do
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
      @station = PL.db.create_station({ user_id: @user.id, 
                                          spins_per_week: spins_per_week 
                                       })
      @schedule = PL.db.create_schedule({ station_id: @station.id })
      @station = PL.db.update_station({ id: @station.id, schedule_id: @schedule.id })
      
      @schedule.generate_playlist
    end

    describe 'now_playing' do
      it 'returns the currently playing spin' do
        expect(@schedule.now_playing.current_position).to eq(1)
      end

      it 'still returns now_playing later' do
        Timecop.travel(2014,5,9, 11,12)
        expect(@schedule.now_playing.current_position).to eq(21)
      end
    end

    describe 'next_spin' do
      it 'returns the next_spin' do
        expect(@schedule.next_spin.current_position).to eq(2)
      end

      it 'returns a CommercialBlock if the next spin should be one' do
        Timecop.travel(2014,5,9, 13)
        expect(@schedule.next_spin).to be_a(PL::CommercialBlock)
      end
    end

    describe 'active?' do
      it 'returns true if the station has been running' do
        Timecop.travel(Time.local(2014,5,9, 10,1))
        expect(@schedule.active?).to eq(true)
      end

      it 'returns false if the station needs updating' do
        Timecop.travel(Time.local(2014,5,9, 11))
        expect(@schedule.active?).to eq(false)
      end
    end
  end
end
