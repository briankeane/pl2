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

  	it 'can be retrieved by id' do
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

  	it "can be deleted, returning the deleted song object" do
  		id = @song.id
  		result = db.delete_song(id)
  		expect(result.id).to eq(id)
  		expect(db.get_song(id)).to be_nil
  	end

  	it 'returns nil if attempting to delete a non-existent song' do
  		result = db.delete_song(99999)
  		expect(result).to be_nil
  	end

    it "finds out if a song exists" do
      expect(db.song_exists?({ title: "Bar Lights", artist: "Brian Keane", album: "Coming Home"})).to eq(true)
      expect(db.song_exists?({ title: "Bar Nights", artist: "Brian Keane", album: "Coming Home"})).to eq(false)
      expect(db.song_exists?({ title: "Bar Lights", artist: "Krian Beane", album: "Coming Home"})).to eq(false)
      expect(db.song_exists?({ title: "Bar Lights", artist: "Brian Keane", album: "Going falseHome"})).to eq(false)
    end
  end

  describe 'song retrieval tests' do
    before do
      @song1 = db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                   audio_id: 2 })
      @song2 = db.create_song({ title: "Bar Nights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                   audio_id: 2 })
      @song3 = db.create_song({ title: "Bar Brights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                   audio_id: 2 })
      @song4 = db.create_song({ title: "Bar First", artist: "Bob Dylan", duration: 226000, sing_start: 5000, sing_end: 208000,
                                   audio_id: 2 })
      @song5 = db.create_song({ title: "Hell", artist: "Bob Dylan", duration: 226000, sing_start: 5000, sing_end: 208000,
                                   audio_id: 2 })
    end

    it "gets a list of songs by title" do
      songlist = db.get_songs_by_title("Bar")
      expect(songlist.size).to eq(4)
      expect(songlist[0].title).to eq("Bar Brights")
      expect(songlist[3].title).to eq("Bar Nights")
    end

    it "gets a list of songs by artist" do
      songlist = db.get_songs_by_artist("Brian Keane")
      expect(songlist.size).to eq(3)
      expect(songlist[0].title).to eq("Bar Brights")
      expect(songlist[2].title).to eq("Bar Nights")
    end
    
    it "returns a list of all songs in the database in the proper order" do
      all_songs = db.get_all_songs
      expect(all_songs.size).to eq(5)
      expect(all_songs[0].title).to eq("Bar First")
      expect(all_songs[1].title).to eq("Hell")
      expect(all_songs[2].title).to eq("Bar Brights")
      expect(all_songs[3].title).to eq("Bar Lights")
      expect(all_songs[4].title).to eq("Bar Nights")
    end

	end


  #################
  #  Commentaries #
  #################
  describe 'a commentary' do
  	before(:each) do
  		@commentary = db.create_commentary({ current_position: 2,
  																					duration: 5000,
  																					station_id: 3,
  																					key: 'ThisIsAKey.mp3' })
  	end

  	it 'can be created' do
  		# UNCOMMENT AFTER SPINS ARE CREATED
  		#expect(@commentary.current_position).to eq(2)
  		expect(@commentary.duration).to eq(5000)
  		expect(@commentary.station_id).to eq(3)
  		expect(@commentary.key).to eq('ThisIsAKey.mp3')
  	end

  	it 'can be retrieved' do
  		gotten_commentary = db.get_commentary(@commentary.id)
  		expect(gotten_commentary.duration).to eq(5000)
  		expect(gotten_commentary.station_id).to eq(3)
  	end

  	it 'can be updated' do
  		db.update_commentary({ id: @commentary.id, key: 'AnotherKey.mp3' })
  		expect(db.get_commentary(@commentary.id).key).to eq('AnotherKey.mp3')
  	end

  	it 'can be deleted, returning the deleted commentary object' do
  		deleted_commentary = db.delete_commentary(@commentary.id)
  		expect(db.get_commentary(@commentary.id)).to be_nil
  		expect(deleted_commentary.duration).to eq(5000)
  	end
  end
  #################
  # Commercials   #
  #################
  describe 'a commercial' do
  	before(:each) do
  		@commercial = db.create_commercial({ sponsor_id: 1, duration: 15000, key: 'ThisIsAKey.mp3' })
  	end

  	it 'can be created' do
  		expect(@commercial.id).to be_a(Fixnum)
  		expect(@commercial.sponsor_id).to eq(1)
  		expect(@commercial.key).to eq('ThisIsAKey.mp3')
  	end

  	it 'can be deleted' do
  		deleted_commercial = db.delete_commercial(@commercial.id)
  		expect(deleted_commercial.duration).to eq(15000)
  		#expect(db.get_commercial).to be_nil
  	end

  	it 'can be retrieved' do
  		gotten_commercial = db.get_commercial(@commercial.id)
  		expect(gotten_commercial.duration).to eq(15000)
  		expect(gotten_commercial.id).to eq(@commercial.id)
  	end

  	it 'can be updated' do
  		updated_commercial = db.update_commercial({ id: @commercial.id, key: 'AnotherKey.mp3', duration: 15001, sponsor_id: 2 })
  		expect(updated_commercial.id).to eq(@commercial.id)
  		expect(db.get_commercial(@commercial.id).key).to eq('AnotherKey.mp3')
  		expect(updated_commercial.duration).to eq(15001)
  		expect(updated_commercial.sponsor_id).to eq(2)
  	end
  end

  #####################
  # Commercial_Blocks #
	#####################
	describe 'a commercial_block' do
		before(:each) do
			@commercial_block = db.create_commercial_block({ commercials: [1,2] })
		end

		it 'is created' do
			expect(@commercial_block.id).to be_a(Fixnum)
			expect(@commercial_block.commercials).to eq([1,2])
		end

		it 'can be gotten' do
			expect(db.get_commercial_block(@commercial_block.id).id).to eq(@commercial_block.id)
		end

		it 'can be edited' do
			updated_cb = db.update_commercial_block({ id: @commercial_block.id, commercials: [3,4,5] })
			expect(updated_cb.id).to eq(@commercial_block.id)
			expect(db.get_commercial_block(@commercial_block.id).commercials).to eq([3,4,5])
		end

		it 'can be deleted' do
			deleted_cb = db.delete_commercial_block(@commercial_block.id)
			expect(deleted_cb.commercials).to eq([1,2])
			expect(db.get_commercial_block(deleted_cb.id)).to be_nil
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

		it 'updates a station' do
			updated_station = db.update_station({ id: @station.id,
																						secs_of_commercial_per_hour: 3 })
			expect(updated_station.secs_of_commercial_per_hour).to eq(3)
			expect(db.get_station(@station.id).secs_of_commercial_per_hour).to eq(3)
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

  ###############
  #   spins     #
  ###############
  describe 'a spin' do
    before(:each) do
      @spins = []
      20.times do |i|
        @spins[i] = db.schedule_spin({ station_id: 1,
                                  current_position: (i+1),
                                  audio_block_type: 'song',
                                  audio_block_id: (i+2) })
      end
    end

    it 'is created' do
      expect(@spins[0].current_position).to eq(1)
      expect(@spins[0].audio_block_type).to eq('song')
      expect(@spins[0].audio_block_id).to eq(2)
      expect(@spins[0].id).to be_a(Fixnum)
    end

    it "returns the current_playlist in the right order" do
      expect(db.get_current_playlist(1).size).to eq(20)
      expect(db.get_current_playlist(1)[0].current_position).to eq(1)
      expect(db.get_current_playlist(1)[2].current_position).to eq(3)
      expect(db.get_current_playlist(1)[3].current_position).to eq(4)
    end
  end

  ##################
  #   log_entries  #   
  ##################
  describe 'a log entry' do
    before(:each) do
      @log_entries = []
      30.times do |i|
        @log_entries << db.create_log_entry({station_id: 4,
                                         current_position: 76 + i,
                                         audio_block_type: 'song',
                                         audio_block_id: 375 + i,
                                         airtime: Time.new(1983, 4, 15, 18) + (i*360),
                                         listeners_at_start: 55 + i,
                                         listeners_at_finish: 57 + i
                                         })
      end
    end

    it 'can be created' do
      expect(@log_entries[0].id).to be_a(Fixnum)
      expect(@log_entries[0].station_id).to eq(4)
      expect(@log_entries[0].current_position).to eq(76)
      expect(@log_entries[0].audio_block_type).to eq('song')
      expect(@log_entries[0].audio_block_id).to eq(375)
      expect(@log_entries[0].airtime.to_s).to eq(Time.new(1983, 4, 15, 18).to_s)
      expect(@log_entries[0].listeners_at_start).to eq(55)
      expect(@log_entries[0].listeners_at_finish).to eq(57)
    end

    it 'can get recent entries' do
      gotten_entries = db.get_recent_log_entries({ station_id: 4, count: 15})
      expect(gotten_entries.size).to eq(15)
      expect(gotten_entries[0].current_position).to eq(105)
      expect(gotten_entries[14].current_position).to eq(91)
    end

    it 'can get a full station log' do
      gotten_log = db.get_full_station_log(4)
      expect(gotten_log.size).to eq(30)
      expect(gotten_log[0].current_position).to eq(105)
      expect(gotten_log[29].current_position).to eq(76)
    end
  end
end