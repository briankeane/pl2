require 'spec_helper'
require 'timecop'
require 'pry-debugger'

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


    it "can see if it's got a playlist" do
      expect(@schedule.playlist_exists?).to eq(false)
      PL.db.create_spin({ schedule_id: @schedule.id, current_position: 1 })
      expect(@schedule.playlist_exists?).to eq(true)
    end

    it "grabs a timezone from the station" do
      expect(@schedule.timezone).to eq('Central Time (US & Canada)')
    end

    it "can get it's station" do
      expect(@schedule.station.id).to eq(@station.id)
    end 
  end

  describe 'playlist functions' do
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

    it 'generate_playlist creates a first playlist' do
      generated_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(generated_playlist.size).to eq(5560)
      expect(PL.db.get_full_station_log(@station.id).size).to eq(1)
    end

    it 'generate_playlist ends at the right time' do
      generated_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(generated_playlist.last.estimated_airtime.day).to eq(22)
      expect(generated_playlist.last.estimated_end_time.day).to eq(23)
    end


    it 'generate_playlist continues the playlist' do
      Timecop.travel(Time.local(2014,5,21))
      @schedule.generate_playlist
      generated_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(generated_playlist.last.estimated_airtime.day).to eq(29)
      expect(generated_playlist.last.estimated_end_time.day).to eq(30)
    end

    it 'generate_playlist updates the @last_accurate_current_position' do
      expect(@schedule.last_accurate_current_position).to eq(5561)
      expect(@schedule.last_accurate_airtime.to_s).to eq('2014-05-22 23:59:40 -0500')
    end

    it "finds it's own end_time" do
      expect(@schedule.end_time.to_s).to eq(Time.local(2014,5,23, 0,2,50).to_s)
    end

    it 'returns the currently playing spin' do
      expect(@schedule.now_playing.current_position).to eq(1)
      Timecop.travel(Time.local(2014,5,10,17))
      expect(@schedule.now_playing.current_position).to eq(530)
    end

    it 'returns the currently playing spin if its a commercial' do
      Timecop.travel(Time.local(2014,5,10,17))
      expect(@schedule.now_playing.current_position).to eq(530)
      Timecop.travel(Time.local(2014,5,10, 17,1,30))
      expect(@schedule.now_playing.audio_block).to be_a(PL::CommercialBlock)
      expect(@schedule.now_playing.airtime.to_s).to eq(Time.local(2014,5,10, 17,1,20).to_s)
      Timecop.travel(Time.local(2014,5,10, 17,4,30))
      expect(@schedule.now_playing.current_position).to eq(531)
    end
    
    it 'brings the station current' do
      Timecop.travel(Time.local(2014,5,10,17))
      @schedule.bring_current
      expect(@schedule.now_playing.current_position).to eq(530)
      expect(PL.db.get_full_station_log(@station.id).size).to eq(591)
    end

    it 'tells if the station is inactive -- no playlist yet' do
      schedule2 = PL.db.create_schedule({ station_id: 3 })
      expect(schedule2.active?).to eq(nil)
    end

    it 'tells if the station is active or inactive -- its been off' do
      expect(@schedule.active?).to eq(true)
      Timecop.travel(Time.local(2014,5,10,17))
      expect(@schedule.active?).to eq(false)
    end

    it 'updates estimated airtimes' do
      PL.db.add_spin({ schedule_id: @schedule.id, 
                        add_position: 35,
                        audio_block_id: @songs[0].id
                        })
      
      @schedule = PL.db.update_schedule({ id: @schedule.id,
                                            last_accurate_current_position: 34 })
      @schedule.update_estimated_airtimes({ end_time: Time.local(2014,5,9, 12) })
      expect(@schedule.last_accurate_current_position).to eq(37)
      expect(@schedule.last_accurate_airtime.to_s).to eq(Time.local(2014,5,9, 12,6).to_s)
      expect(PL.db.get_full_playlist(@schedule.id)[34].estimated_airtime.to_s).to eq(Time.local(2014,5,9, 11,59,50).to_s)
    end

    it 'updates estimated airtimes starting with a commercial' do
      PL.db.add_spin({ schedule_id: @schedule.id, 
                        add_position: 38,
                        audio_block_id: @songs[0].id
                        })
      @schedule = PL.db.update_schedule({ id: @schedule.id,
                                            last_accurate_current_position: 37 })
      @schedule.update_estimated_airtimes({ end_time: Time.local(2014,5,9, 12,10) })
      playlist = PL.db.get_full_playlist(@schedule.id)
      expect(playlist[36].current_position).to eq(38)
      expect(playlist[36].estimated_airtime.to_s).to eq(Time.local(2014,5,9,12,9,10).to_s)
    end

    it 'updates estimated airtimes for the rest of the playlist' do
      PL.db.add_spin({ schedule_id: @schedule.id, 
                        add_position: 38,
                        audio_block_id: @songs[0].id
                        })
      @schedule = PL.db.update_schedule({ id: @schedule.id,
                                            last_accurate_current_position: 37 })
      @schedule.update_estimated_airtimes
      expect(@schedule.last_accurate_airtime.to_s).to eq(Time.local(2014,5,23, 0,5,50).to_s)
      expect(@schedule.last_accurate_current_position).to eq(5562)
    end

    it 'brings the station current if commercial is scheduled' do
      Timecop.travel(Time.local(2014,5,10, 0,3))
      expect(@schedule.now_playing.current_position).to eq(240)
      expect(@schedule.now_playing.audio_block).to be_a(PL::CommercialBlock)
    end

    describe 'GetProgram' do
      it 'returns a program for a particular time' do
        program = @schedule.get_program({ start_time: Time.local(2014,5,10, 17) })
        expect(program[1].estimated_airtime.to_s).to eq(Time.local(2014,5,10, 17,04,20).to_s)
        expect(program[1].current_position).to eq(531)
        expect(program[0]).to be_a(PL::CommercialBlock)
        expect(program[57].current_position).to eq(581)
      end

      it 'returns a program given current_positions' do
        program = @schedule.get_program_by_current_positions({ starting_current_position: 530,
                                                                ending_current_position: 581 })
        expect(program[0].estimated_airtime.to_s).to eq(Time.local(2014,5,10, 16,58,10).to_s)
        expect(program[0].current_position).to eq(530)
        expect(program[1]).to be_a(PL::CommercialBlock)
        expect(program[57].current_position).to eq(581)
      end
      it 'returns a blank array if time is beyond scope' do
        program = @schedule.get_program({ start_time: Time.local(2014,5,23) })
        expect(program).to eq([])
      end

      it 'extends the schedule if time should be created' do
        Timecop.travel(Time.local(2014,5,19))
        program = @schedule.get_program({ start_time: Time.local(2014,5,23) })
        expect(program.size).to eq(58)
      end
    end

    after(:all) do
      Timecop.return
    end
  end
end
