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
			expect(generated_playlist.size).to eq(5560)
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
				expect(@station.now_playing.current_position).to eq(23)
			end
		end

		describe 'end_time' do
			it 'returns the proper end_time' do
				expect(@station.end_time.to_s).to eq('2014-05-23 00:02:50 -0500')
			end

			it 'still returns the proper end_time' do
				PL.db.create_spin({ station_id: @station.id,
															audio_block_id: @songs[0].id,
															current_position: 5562 })
				expect(@station.end_time.to_s).to eq('2014-05-23 00:09:00 -0500')
			end
		end

		describe 'offset' do
			it 'returns the proper station offset' do
				new_spin = PL.db.create_spin({ station_id: @station.id,
											audio_block_id: @songs[0].id,
											current_position: 5562 })
				expect(@station.offset).to eq(-370.0)

				PL.db.delete_spin(new_spin.id)
				expect(@station.offset).to eq(0)
			end
		end

		after (:all) do
			Timecop.return
		end
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

		describe 'last_log_entry' do
			it 'gets the last log entry' do
				expect(@station.last_log_entry.current_position).to eq(14)
			end

			it 'still gets the last log entry' do
				new_log = PL.db.create_log_entry({ station_id: @station.id,
																						current_position: 999 })
				expect(@station.last_log_entry.current_position).to eq(999)
			end
		end

		it 'does nothing if the station has been running' do
			Timecop.travel(Time.local(2014, 4, 14, 11, 55))
			@station.make_log_current
			expect(PL.db.get_log_entry(@log.id).airtime.to_s).to eq(Time.new(2014, 4, 14, 11, 56).to_s)
			expect(PL.db.get_current_playlist(@station.id).size).to eq(4)
		end

		it 'updates if the station has been off' do
			Timecop.travel(Time.local(2014, 4, 14, 11, 59))
			@station.make_log_current
			log = PL.db.get_full_station_log(@station.id)
			expect(log[1].airtime.to_s).to eq(Time.local(2014, 4, 14, 11, 56).to_s)
			expect(log[0].airtime.to_s).to eq(Time.local(2014, 4, 14, 11, 59).to_s)
			expect(log.size).to eq(2)
			expect(log[0].current_position).to eq(15)
			expect(log[1].current_position).to eq(14)
		end

		it 'accounts for commercials properly' do
			Timecop.travel(Time.local(2014,4,14, 12,9))
			@station.make_log_current
			log = PL.db.get_full_station_log(@station.id)

			expect(log.size).to eq(5)
			expect(log[2].duration).to eq(150000)
		end

		it "doesn't mess up when 1st log is a commercial" do
			Timecop.travel(Time.local(2014,4,14, 12))
			@station.make_log_current
			Timecop.travel(Time.local(2014,4,14, 12,9))
			@station.make_log_current
			log = PL.db.get_full_station_log(@station.id)

			expect(log.size).to eq(5)
			expect(log[2].duration).to eq(150000)
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
				expect(@station.log_end_time.to_s).to eq('2014-04-14 11:59:00 -0500')
				log2 = PL.db.create_log_entry({ station_id: @station.id,
																			current_position: 14,
																			airtime: Time.new(2014, 4, 14, 11, 57),
																			duration: 180000 
																			})
				expect(@station.log_end_time.to_s).to eq('2014-04-14 12:00:00 -0500')
			end

			describe 'estimated_airtime' do
				it 'updates airtimes correctly' do
					Timecop.travel(Time.local(2014, 4, 14, 11, 56))
					@station.update_estimated_airtimes
					expect(@spin1.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 11, 59).to_s)
					expect(@spin2.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 04,30).to_s)
					expect(@spin3.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 07,30).to_s)
					expect(@spin4.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 10,30).to_s)
				end

				it 'works if it starts just before a commercial' do
					Timecop.travel(Time.local(2014, 4, 14, 12, 00))
					@station.update_estimated_airtimes
					expect(@spin2.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 04,30).to_s)
					expect(@spin3.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 07,30).to_s)
					expect(@spin4.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 10,30).to_s)
				end

				it 'works if it starts mid-commercial' do
					Timecop.travel(Time.local(2014, 4, 14, 12, 03))
					@station.update_estimated_airtimes
					expect(@spin2.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 04,30).to_s)
					expect(@spin3.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 07,30).to_s)
					expect(@spin4.estimated_airtime.to_s).to eq(Time.local(2014, 4, 14, 12, 10,30).to_s)
				end
			end
		end



		after (:all) do
			Timecop.return
		end
	end

end