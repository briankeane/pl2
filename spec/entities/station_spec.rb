require 'spec_helper'
require 'Timecop'

describe 'a station' do
	before(:each) do
		@song1 = PL::Song.new({ id: 1 })
		@song2 = PL::Song.new({ id: 2 })
		@song3 = PL::Song.new({ id: 3 })
		@station = PL::Station.new({ id: 1,
		   secs_of_commercial_per_hour: 3,
		                       user_id: 2,
		                         heavy: [@song1.id],
		                        medium: [@song2.id],
		                         light: [@song3.id],
		                         created_at: Time.new(1970),
		                         updated_at: Time.new(1970, 1, 2) })
	end

	it 'is created with an id, secs_of_commercial_per_hour, user_id, and heavy, medium, and light rotation arrays' do
		expect(@station.id).to eq(1)
		expect(@station.secs_of_commercial_per_hour).to eq(3)
		expect(@station.user_id).to eq(2)
		expect(@station.spins_per_week[@song1.id]).to eq(PL::HEAVY_ROTATION)
		expect(@station.spins_per_week[@song2.id]).to eq(PL::MEDIUM_ROTATION)
		expect(@station.spins_per_week[@song3.id]).to eq(PL::LIGHT_ROTATION)
		expect(@station.created_at).to eq(Time.new(1970))
		expect(@station.updated_at).to eq(Time.new(1970, 1, 2))
	end

	it "allows editing of the spins_per_week hash" do
		@station.spins_per_week[5] = 10
		expect(@station.spins_per_week[5]).to eq(10)
	end

	describe 'playlist functions' do
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

		it 'creates a first playlist' do
			generated_playlist = PL.db.get_current_playlist(@station.id)
			expect(generated_playlist.size).to eq(5561)
			expect(PL.db.get_full_station_log(@station.id).size).to eq(1)
		end

		it 'ends at the correct time' do
			Timecop.travel(Time.local(2014, 5,9, 12))
			expect(@station.original_playlist_end_time.to_s).to eq('2014-05-23 00:02:50 -0500')
		end

		describe 'now_playing' do
			it 'returns the currently playing spin' do
				expect(@station.now_playing.current_position).to eq(1)			
			end

			it 'still returns the current playing spin later' do
				Timecop.travel(2014,5,9, 11, 12)
				expect(@station.now_playing.current_position).to eq(3)
			end
		end

		after (:all) do
			Timecop.return
		end
	end

	describe 'make_log_current' do
		before (:each) do
			@station = PL.db.create_station({ user_id: 1 })
			@song = PL.db.create_song({ duration: 180000 })
			@spin1 = PL.db.schedule_spin({ current_position: 15,
																			station_id: @station.id,
																			audio_block_id: @song.id,
																			estimated_airtime: Time.new(2014, 4, 15, 11, 25) 
																			})
			@spin2 = PL.db.schedule_spin({ current_position: 16,
																			station_id: @station.id,
																			audio_block_id: @song.id,																			
																			estimated_airtime: Time.new(2014, 4, 15, 11, 28) 
																			})
			@spin3 = PL.db.schedule_spin({ current_position: 17,
																			station_id: @station.id,
																			audio_block_id: @song.id,																			
																			estimated_airtime: Time.new(2014, 4, 15, 12, 31) 
																			})
			@spin4 = PL.db.schedule_spin({ current_position: 18,
																			station_id: @station.id,
																			audio_block_id: @song.id,
																			estimated_airtime: Time.new(2014, 4, 15, 12, 38) 
																			})
			@log = PL.db.create_log_entry({ station_id: @station.id,
																			current_position: 14,
																			airtime: Time.new(2014, 4, 14, 11, 54),
																			duration: 180000 
																			})
		end

		describe 'active?' do
			it 'returns true if the station has been running' do
				Timecop.travel(Time.local(2014, 4,14, 11,55))
				expect(@station.active?).to eq(true)
			end

			it 'returns false if the station needs updating' do
				Timecop.travel(Time.local(2014, 4,14, 13,05))
				expect(@station.active?).to eq(false)
			end
		end

		describe 'log_end_time' do
			it 'returns the time the log ends' do
				expect(@station.log_end_time.to_s).to eq('2014-04-14 11:57:00 -0500')
				log2 = PL.db.create_log_entry({ station_id: @station.id,
																			current_position: 14,
																			airtime: Time.new(2014, 4, 14, 11, 57),
																			duration: 180000 
																			})
				expect(@station.log_end_time.to_s).to eq('2014-04-14 12:00:00 -0500')
			end
		end


		it 'does nothing if the station has been running' do
			Timecop.travel(Time.local(2014, 4, 14, 11, 55))
			@station.make_log_current
			expect(PL.db.get_log_entry(@log.id).airtime.to_s).to eq(Time.new(2014, 4, 14, 11, 54).to_s)
			expect(PL.db.get_current_playlist(@station.id).size).to eq(4)
		end

		after (:all) do
			Timecop.return
		end
	end

end