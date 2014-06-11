require 'spec_helper'

describe 'a database' do

	#let(:db) { described_class.new("test") }
	db = PL::Database::InMemory.new

	before { db.clear_everything }

	describe 'a database' do

		##############
    #   Users    #
    ##############
		before(:each) do
			@user = db.create_user({ twitter: 'BrianKeaneTunes',
							twitter_uid: 756,
							email: 'lonesomewhistle_gmail.com',
							birth_year: 1977,
							gender: 'male' })
		end
		
		it 'creates a user' do
			expect(@user.id).to_not be_nil
			expect(@user.twitter).to eq('BrianKeaneTunes')
			expect(@user.twitter_uid).to eq(756)
			expect(@user.birth_year).to eq(1977)
			expect(@user.gender).to eq('male')
		end

		it 'is gotten by id' do
			user = db.get_user(@user.id)
			expect(user.twitter).to eq('BrianKeaneTunes')
		end

		it 'can be gotten by twitter' do
			user = db.get_user_by_twitter('BrianKeaneTunes')
			expect(user.id).to eq(@user.id)
		end

		it 'can be updated' do
			old_update_time = @user.updated_at
			db.update_user({ id: @user.id,
															birth_year: 1900,
															twitter: 'bob',
															twitter_uid: 100,
															gender: 'unsure',
															email: 'bob@bob.com' })
			user = db.get_user(@user.id)
			expect(user.birth_year).to eq(1900)
			expect(user.twitter).to eq('bob')
			expect(user.twitter_uid).to eq(100)
			expect(user.gender).to eq('unsure')
			expect(user.email).to eq('bob@bob.com')
			expect(user.updated_at > old_update_time).to eq(true)
		end

		it 'can be deleted' do
			deleted_user = db.delete_user(@user.id)
			expect(db.get_user(@user.id)).to be_nil
			expect(deleted_user.twitter).to eq('BrianKeaneTunes')
		end

		it 'returns nil if attempt to delete non-existent user' do
			deleted = db.delete_user(999)
			expect(deleted).to be_nil
		end
	end

	##############
  #   Songs    #
  ##############
  describe 'a song' do
  	before (:each) do
  		@song = db.create_song({ artist: 'Brian Keane',
  											title: 'Bar Lights',
  											album: 'Coming Home',
  											duration: 19000,
  											key: 'ThisIsAKey.mp3' })
  	end

  	it 'is created with id, artist, title, album, duration, key' do
  		expect(@song.artist).to eq('Brian Keane')
  		expect(@song.title).to eq('Bar Lights')
  		expect(@song.album).to eq('Coming Home')
  		expect(@song.duration).to eq(19000)
  		expect(@song.key).to eq('ThisIsAKey.mp3')
  		expect(@song.id).to be_a(Fixnum)
  	end

  	it 'can be gotten by id' do
  		gotten_song = db.get_song(@song.id)
  		expect(gotten_song.artist).to eq('Brian Keane')
  		expect(gotten_song.title).to eq('Bar Lights')
  		expect(gotten_song.album).to eq('Coming Home')
  		expect(gotten_song.duration).to eq(19000)
  		expect(gotten_song.key).to eq('ThisIsAKey.mp3')
  		expect(gotten_song.id).to be_a(Fixnum)
  	end

  	it 'can be updated' do
  		db.update_song({ id: @song.id, artist: 'Bob' })
  		db.update_song({ id: @song.id, title: 'Song By Bob' })
  		db.update_song({ id: @song.id, album: 'Album By Bob' })
  		db.update_song({ id: @song.id, duration: 20000 })
  		db.update_song({ id: @song.id, key: 'BobsKey.mp3' })

  		updated_song = db.get_song(@song.id)
  		expect(updated_song.artist).to eq('Bob')
  		expect(updated_song.title).to eq('Song By Bob')
  		expect(updated_song.album).to eq('Album By Bob')
  		expect(updated_song.duration).to eq(20000)
  		expect(updated_song.key).to eq('BobsKey.mp3')
  	end

  	it "returns false if song-to-update doesn't exist" do
  		result = db.update_song({ id: 9999999, artist: 'Bob' })
  		expect(result).to eq(false)
  	end

  	it "deletes a song, returning the deleted song object" do
  		id = @song.id
  		result = db.delete_song(id)
  		expect(result.id).to eq(id)
  		expect(db.get_song(id)).to be_nil
  	end

  	it 'returns nil if attempting to delete a non-existent song' do
  		result = db.delete_song(99999)
  		expect(result).to be_nil
  	end
	end

	##############
	#  Stations  #
	##############
	describe 'a station' do
		before(:each) do
			@song1 = db.create_song({ artist: 'Brian Keane', title: 'Bar Lights' })
			@song2 = db.create_song({ artist: 'Rachel Loy', title: 'Stepladder' })
			@song3 = db.create_song({ artist: 'Donny Hathaway', title: "You've Got a Friend" })
			@station = db.create_station({ user_id: 1,
																			secs_of_commercial_per_hour: 2,
																			heavy: [@song1.id],
																			medium: [@song2.id],
																			light: [@song3.id] })
		end

		it 'creates a station' do
			expect(@station.id).to be_a(Fixnum)
			expect(@station.user_id).to eq(1)
			expect(@station.secs_of_commercial_per_hour).to eq(2)
			expect(@station.spins_per_week[@song1.id]).to eq(PL::HEAVY_ROTATION)
			expect(@station.spins_per_week[@song2.id]).to eq(PL::MEDIUM_ROTATION)
			expect(@station.spins_per_week[@song3.id]).to eq(PL::LIGHT_ROTATION)
		end

		it 'gets a station' do
			gotten_station = db.get_station(@station.id)
			expect(gotten_station.secs_of_commercial_per_hour).to eq(2)
			expect(gotten_station.user_id).to eq(1)
		end
	end

  ###################
  #  SpinFrequency  #
  ###################
  describe 'a rotation_spins_per_week' do
  	before(:each) do
  		@station = db.create_station({ user_id: 1 })
  		@heavy_rl = db.create_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: PL::HEAVY_ROTATION })
  		@medium_rl = db.create_spin_frequency({ song_id: 2, station_id: @station.id, spins_per_week: PL::MEDIUM_ROTATION })
  		@light_rl = db.create_spin_frequency({ song_id: 3, station_id: @station.id, spins_per_week: PL::LIGHT_ROTATION })
  	end


  	it 'stores the rotation_spins_per_week for each song' do
  		updated_station = db.get_station(@station.id)
  		expect(updated_station.spins_per_week.size).to eq(3)
  		expect(updated_station.spins_per_week[1]).to eq(PL::HEAVY_ROTATION)
  		expect(updated_station.spins_per_week[2]).to eq(PL::MEDIUM_ROTATION)
  		expect(updated_station.spins_per_week[3]).to eq(PL::LIGHT_ROTATION)
  	end

  	it 'returns an updated version of the station' do
  		expect(@heavy_rl.spins_per_week[1]).to eq(PL::HEAVY_ROTATION)
  		expect(@heavy_rl.spins_per_week[2]).to eq(PL::MEDIUM_ROTATION)
  	end

  	it 'can update a spin frequency' do
  		updated_station = db.update_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: 1 })
  		expect(db.get_station(@station.id).spins_per_week[1]).to eq(1)
  	end

  	it 'can delete a spin frequency' do
  		updated_station = db.update_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: 0 })
  		expect(db.get_station(@station.id).spins_per_week[1]).to eq(nil)
  	end
  end
end