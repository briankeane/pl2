require 'spec_helper'
require 'Timecop'

shared_examples 'a badass database' do

  let(:db) { described_class.new("test") }
  #db = PL::Database::InMemory.new

  before { db.clear_everything }

  describe 'a database' do

    ##############
    #   Users    #
    ##############
    before(:each) do
      @user = db.create_user({ twitter: 'BrianKeaneTunes',
              twitter_uid: '756',
              email: 'lonesomewhistle_gmail.com',
              birth_year: 1977,
              gender: 'male' })
    end
    
    it 'creates a user' do
      expect(@user.id).to_not be_nil
      expect(@user.twitter).to eq('BrianKeaneTunes')
      expect(@user.twitter_uid).to eq('756')
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

    it 'can be gotten by twitter_uid' do
      user = db.get_user_by_twitter_uid('756')
      expect(user.id).to eq(@user.id)
    end

    it 'can be updated' do
      old_update_time = @user.updated_at
      db.update_user({ id: @user.id,
                              birth_year: 1900,
                              twitter: 'bob',
                              twitter_uid: '100',
                              gender: 'unsure',
                              email: 'bob@bob.com' })
      user = db.get_user(@user.id)
      expect(user.birth_year).to eq(1900)
      expect(user.twitter).to eq('bob')
      expect(user.twitter_uid).to eq('100')
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

    it 'gets all users' do
      5.times { |i| db.create_user({ twitter: i.to_s }) }
      all_users = db.get_all_users
      expect(all_users.count).to eq(6)
      expect(all_users[0].twitter).to eq('0')
      expect(all_users[5].twitter).to eq('BrianKeaneTunes')
    end

    it 'destroys all users' do
      5.times { |i| db.create_user({ twitter: i.to_s }) }
      db.destroy_all_users
      expect(db.get_all_users.count).to eq(0)
    end

  end

  ################
  # Audio_Blocks #
  ################
  describe 'audio_block' do
    before(:each) do
      @song = db.create_song({ artist: 'Brian Keane',
                          title: 'Bar Lights',
                          album: 'Coming Home',
                          duration: 19000,
                          key: 'ThisIsAKey.mp3' })
    end

    it 'returns the audio_block' do
      ab = db.get_audio_block(@song.id)
      expect(ab.artist).to eq('Brian Keane')
      expect(ab.title).to eq('Bar Lights')
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
                        key: 'ThisIsAKey.mp3',
                        echonest_id: 'THISISANENID' })
    end

    it 'is created with id, artist, title, album, duration, key' do
      expect(@song.artist).to eq('Brian Keane')
      expect(@song.title).to eq('Bar Lights')
      expect(@song.album).to eq('Coming Home')
      expect(@song.duration).to eq(19000)
      expect(@song.key).to eq('ThisIsAKey.mp3')
      expect(@song.id).to be_a(Fixnum)
      expect(@song.echonest_id).to eq('THISISANENID')
    end

    it 'can be retrieved by id' do
      gotten_song = db.get_song(@song.id)
      expect(gotten_song.artist).to eq('Brian Keane')
      expect(gotten_song.title).to eq('Bar Lights')
      expect(gotten_song.album).to eq('Coming Home')
      expect(gotten_song.duration).to eq(19000)
      expect(gotten_song.key).to eq('ThisIsAKey.mp3')
      expect(gotten_song.id).to be_a(Fixnum)
      expect(gotten_song.echonest_id).to eq('THISISANENID')
    end

    it 'can be updated' do
      db.update_song({ id: @song.id, artist: 'Bob' })
      db.update_song({ id: @song.id, title: 'Song By Bob' })
      db.update_song({ id: @song.id, album: 'Album By Bob' })
      db.update_song({ id: @song.id, duration: 20000 })
      db.update_song({ id: @song.id, key: 'BobsKey.mp3' })
      db.update_song({ id: @song.id, echonest_id: 'ANOTHERENID'})

      updated_song = db.get_song(@song.id)
      expect(updated_song.artist).to eq('Bob')
      expect(updated_song.title).to eq('Song By Bob')
      expect(updated_song.album).to eq('Album By Bob')
      expect(updated_song.duration).to eq(20000)
      expect(updated_song.key).to eq('BobsKey.mp3')
      expect(updated_song.echonest_id).to eq('ANOTHERENID')
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
    end
  end

  describe 'song retrieval tests' do
    before do
      @song1 = db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000,
                                   key: 'ThisIsAKey.mp3', echonest_id: 'THISISANENID' })
      @song2 = db.create_song({ title: "Bar Nights", artist: "Brian Keane", duration: 226000,
                                   key: 'ThisIsAKey.mp3', echonest_id: 'THISISANENID2' })
      @song3 = db.create_song({ title: "Bar Brights", artist: "Brian Keane", duration: 226000,
                                   key: 'ThisIsAKey.mp3', echonest_id: 'THISISANENID3' })
      @song4 = db.create_song({ title: "Bar First", artist: "Bob Dylan", duration: 226000,
                                   key: 'ThisIsAKey.mp3', echonest_id: 'THISISANENID4'})
      @song5 = db.create_song({ title: "Hell", artist: "Bob Dylan", duration: 226000,
                                   key: 'ThisIsAKey.mp3', echonest_id: 'THISISANENID5' })
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

    it 'gets a song by its echonest_id' do
      expect(db.get_song_by_echonest_id(@song1.echonest_id).id).to eq(@song1.id)
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
      @commentary = db.create_commentary({ duration: 5000,
                                            schedule_id: 3,
                                            key: 'ThisIsAKey.mp3' })
    end

    it 'can be created' do
      # UNCOMMENT AFTER SPINS ARE CREATED
      #expect(@commentary.current_position).to eq(2)
      expect(@commentary.duration).to eq(5000)
      expect(@commentary.schedule_id).to eq(3)
      expect(@commentary.key).to eq('ThisIsAKey.mp3')
    end

    it 'can be retrieved' do
      gotten_commentary = db.get_commentary(@commentary.id)
      expect(gotten_commentary.duration).to eq(5000)
      expect(gotten_commentary.schedule_id).to eq(3)
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
      @commercial1 = db.create_commercial({ })
      @commercial2 = db.create_commercial({ })
      @commercial3 = db.create_commercial({ })
      @commercial_block = db.create_commercial_block({ commercials: [@commercial1, @commercial2, @commercial3] })
    end

    it 'is created' do
      expect(@commercial_block.id).to be_a(Fixnum)
      expect(@commercial_block.commercials.map { |c| c.id }).to eq([@commercial1.id, @commercial2.id, @commercial3.id])
    end

    it 'can be gotten' do
      expect(db.get_commercial_block(@commercial_block.id).id).to eq(@commercial_block.id)
    end

    it 'can be edited' do
      updated_cb = db.update_commercial_block({ id: @commercial_block.id, duration: 1, estimated_airtime: Time.new(1985,1,1), cb_position: 7 })
      expect(updated_cb.id).to eq(@commercial_block.id)
      expect(db.get_commercial_block(@commercial_block.id).cb_position).to eq(7)
    end

    it 'can be deleted' do
      deleted_cb = db.delete_commercial_block(@commercial_block.id)
      expect(deleted_cb.commercials.map { |c| c.id }).to eq([@commercial1.id, @commercial2.id, @commercial3.id])
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
                                      spins_per_week: { @song1.id => PL::HEAVY_ROTATION,
                                                      @song2.id => PL::MEDIUM_ROTATION,
                                                      @song3.id => PL::LIGHT_ROTATION}
                                   })
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

    it 'gets a station by user_id' do
      gotten_station = db.get_station_by_uid(1)
      expect(gotten_station.id).to eq(@station.id)
    end

    it 'destroys all stations' do
      station1 = db.create_station({ user_id: 1 })
      station2 = db.create_station({ user_id: 2 })
      station3 = db.create_station({ user_id: 3 })
      db.destroy_all_stations
      expect(db.get_station(station1.id)).to be_nil
      expect(db.get_station(station2.id)).to be_nil
      expect(db.get_station(station3.id)).to be_nil
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
      expect(db.get_station(@heavy_rl.id).spins_per_week[1]).to eq(PL::HEAVY_ROTATION)
      expect(db.get_station(@heavy_rl.id).spins_per_week[2]).to eq(PL::MEDIUM_ROTATION)
    end

    it 'can update a spin frequency' do
      updated_station = db.create_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: 1 })
      expect(db.get_station(@station.id).spins_per_week[1]).to eq(1)
    end

    it 'can delete a spin frequency' do
      updated_station = db.delete_spin_frequency({ song_id: 1, station_id: @station.id, spins_per_week: 0 })
      expect(db.get_station(@station.id).spins_per_week[1]).to eq(nil)
    end

    it 'destroys all spin_frequencies' do
      db.destroy_all_spin_frequencies
      expect(db.get_station(@station.id).spins_per_week).to eq({})
    end

  end

  ###############
  #   spins     #
  ###############
  describe 'a spin' do
    it 'checks to see if a playlist exists' do
      db.clear_everything
      expect(db.playlist_exists?(1)).to eq(false)
      db.create_spin({ schedule_id: 1 })
      expect(db.playlist_exists?(1)).to eq(true)
    end

    it 'can mass add spins at once' do
      db.clear_everything
      spins = []
      starting_airtime = Time.local(2014,1,1, 10)
      20.times do |i|
        spins << PL::Spin.new({ schedule_id: 1,
                                  current_position: (i+1),
                                  audio_block_id: (i+2),
                                  estimated_airtime: starting_airtime += 180 })
      end
      
      db.mass_add_spins(spins)
      expect(db.get_spin_by_current_position({schedule_id: 1, current_position: 1 }).id).to_not be_nil
      expect(db.get_full_playlist(1)[1].current_position).to eq(2)
      expect(db.get_full_playlist(1)[0].current_position).to eq(1)
      expect(db.get_full_playlist(1).size).to eq(20)
    end

    before(:each) do
      db.clear_everything
      starting_airtime = Time.local(2014,1,1, 10)
      @spins = []
      20.times do |i|
        @spins[i] = db.create_spin({ schedule_id: 1,
                                  current_position: (i+1),
                                  audio_block_id: (i+2),
                                  estimated_airtime: starting_airtime += 180 })
      end
    end

    it 'is created' do
      expect(@spins[0].current_position).to eq(1)
      expect(@spins[0].audio_block_id).to eq(2)
      expect(@spins[0].id).to be_a(Fixnum)
    end

    it 'can be gotten by id' do
      expect(db.get_spin(@spins[0].id).audio_block_id).to eq(@spins[0].audio_block_id)
    end

    it 'can be removed' do
      old_playlist = db.get_full_playlist(1)
      removed_spin = db.remove_spin({ schedule_id: 1, current_position: 10 })
      new_playlist = db.get_full_playlist(1)
      new_current_positions = new_playlist.map { |spin| spin.current_position }
      expect(new_playlist.size).to eq(19)
      expect(new_current_positions).to eq([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19])
      expect(new_playlist[18].audio_block_id).to eq(old_playlist[19].audio_block_id)
      expect(new_playlist[10].id).to eq(old_playlist[11].id)
      expect(new_playlist[8].id).to eq(old_playlist[8].id)
    end


    it "returns the current_playlist in the right order" do
      expect(db.get_full_playlist(1).size).to eq(20)
      expect(db.get_full_playlist(1)[0].current_position).to eq(1)
      expect(db.get_full_playlist(1)[2].current_position).to eq(3)
      expect(db.get_full_playlist(1)[3].current_position).to eq(4)
    end

    it "gets a partial playlist" do
      playlist = db.get_partial_playlist({ schedule_id: 1,
                                            start_time: Time.local(2014,1,1, 10,5),
                                            end_time: Time.local(2014,1,1, 10,15) })
      expect(playlist.size).to eq(4)
      expect(playlist.first.current_position).to eq(2)
      expect(playlist.last.current_position).to eq(5)

      playlist = db.get_partial_playlist({ schedule_id: 1,
                                            start_time: Time.local(2014,1,1, 10,10,),
                                            end_time: Time.local(2014,1,1, 10,15) })
      expect(playlist.size).to eq(2)
      expect(playlist.first.current_position).to eq(4)
      expect(playlist.last.current_position).to eq(5)
    end

    it 'gets a partial playlist from the beginning' do
      playlist = db.get_partial_playlist({ schedule_id: 1,
                                            end_time: Time.local(2014,1,1, 10,15) })
      expect(playlist.size).to eq(5)
      expect(playlist[0].current_position).to eq(1)
      expect(playlist.last.current_position).to eq(5)
    end

    it 'gets a partial playlist until the end' do
      playlist = db.get_partial_playlist({ schedule_id: 1,
                                            start_time: Time.local(2014,1,1, 10,5) })
      expect(playlist.size).to eq(19)
      expect(playlist.first.current_position).to eq(2)
      expect(playlist.last.current_position).to eq(20)
    end

    it 'gets a partial playlist by starting current_position' do
      playlist = db.get_playlist_by_current_positions({ schedule_id: 1,
                                                        starting_current_position: 10 })
      expect(playlist.size).to eq(11)
      expect(playlist[0].current_position).to eq(10)
      expect(playlist[10].current_position).to eq(20)
    end

    it 'gets a partial playlist by starting and ending positions' do
      playlist = db.get_playlist_by_current_positions({ schedule_id: 1,
                                                        starting_current_position: 10,
                                                        ending_current_position: 15 })
      expect(playlist.size).to eq(6)
      expect(playlist[0].current_position).to eq(10)
      expect(playlist[5].current_position).to eq(15)
    end

    it 'gets the final_spin' do
      final_spin = db.get_final_spin(1)
      expect(final_spin.current_position).to eq(20)
    end

    it 'gets a spin by current_position' do
      expect(db.get_spin_by_current_position({ schedule_id: 1, current_position: 4 }).audio_block_id).to eq(5)
    end

    it 'can be deleted' do
      id = @spins[0].id
      deleted_spin = db.delete_spin(@spins[0].id)

      expect(deleted_spin.id).to eq(id)
      expect(db.get_spin(id)).to eq(nil)
    end

    it 'can be updated' do
      spin = db.create_spin({ schedule_id: 1,
                              current_position: 2,
                              audio_block_id: 3,
                              estimated_airtime: Time.new(2014),
                            })
      updated_spin = db.update_spin({ id: spin.id,
                                      schedule_id: 10,
                                      current_position: 20,
                                      audio_block_id: 30,
                                      estimated_airtime: Time.new(2015) 
                                    })
      expect(spin.id).to eq(updated_spin.id)
      expect(db.get_spin(spin.id).current_position).to eq(20)
      expect(db.get_spin(spin.id).audio_block_id).to eq(30)
      expect(updated_spin.estimated_airtime.to_f.floor).to eq(Time.new(2015).to_f.floor)
    end

    it "returns false if spin to be updated doesn't exist" do
      expect(db.update_spin({ id: 9999 })).to eq(false)
    end

    it 'returns the last scheduled spin for a station' do
      expect(db.get_last_spin(1).current_position).to eq(20)
    end

    it 'returns the next scheduled spin for a station' do
      expect(db.get_next_spin(1).current_position).to eq(1)
    end

    it 'returns the spin after next scheduled' do
      expect(db.get_spin_after_next(1).current_position).to eq(2)
    end

    it 'destroys all spins' do
      db.destroy_all_spins
      expect(db.get_full_playlist(1).size).to eq(0)
    end
  end

  describe 'insert_spin' do
    before(:each) do
      Timecop.travel(Time.local(2014,5,9, 20,30))

      # force station/schedule to use same db as these tests
      expect(PL).to receive(:db).at_least(:once).and_return(db) 

      Timecop.travel(Time.local(2014, 5, 9, 10))
      @user = db.create_user({ twitter: "Bob" })
      @songs = []
      86.times do |i|
        @songs << db.create_song({ title: "#{i} title", artist: "#{i} artist", album: "#{i} album", duration: 190000 })
      end

      # build spins_per_week
      heavy = @songs[0..30]
      medium = @songs[31..65]
      light = @songs[66..85]

      spins_per_week = {}
      heavy.each { |song| spins_per_week[song.id] = PL::HEAVY_ROTATION }
      medium.each { |song| spins_per_week[song.id] = PL::MEDIUM_ROTATION }
      light.each { |song| spins_per_week[song.id] = PL::LIGHT_ROTATION }
      @station = db.create_station({ user_id: @user.id, 
                                          spins_per_week: spins_per_week 
                                       })
      @schedule = db.create_schedule({ station_id: @station.id })
      @schedule.generate_playlist
      @old_playlist_ab_ids = db.get_full_playlist(@schedule.id).map { |spin| spin.audio_block_id }
    end
    
    it 'adds a spin', :slow do
      added_audio_block = db.create_song({ duration: 50000 })
      added_spin = db.add_spin({ schedule_id: @schedule.id,
                                 audio_block_id: added_audio_block.id,
                                 add_position: 15 })
      new_playlist = db.get_full_playlist(@schedule.id)
      expect(new_playlist.size).to eq(@old_playlist_ab_ids.size + 1)
      expect(@old_playlist_ab_ids.last).to eq(new_playlist.last.audio_block_id)
      expect(new_playlist[13].audio_block_id).to eq(added_audio_block.id)
    end

    after(:all) do
      Timecop.return
    end
  end

  describe 'move_spin' do
    before(:each) do

      @spin1 = db.create_spin({ schedule_id: 1, audio_block_id: 1, current_position: 7 })
      @spin2 = db.create_spin({ schedule_id: 1, audio_block_id: 2, current_position: 8 })
      @spin3 = db.create_spin({ schedule_id: 1, audio_block_id: 3, current_position: 9 })
      @spin4 = db.create_spin({ schedule_id: 1, audio_block_id: 4, current_position: 10 })
    end

    it "moves a song backwards and adjusts the playlist around it" do
      db.move_spin({ old_position: 9, new_position: 7, schedule_id: 1 })
      new_playlist = db.get_full_playlist(1)
      expect(new_playlist.map { |spin| spin.audio_block_id }).to eq([3,1,2,4])
    end

    it "moves a song forwards and adjusts the playlist around it" do
      db.move_spin({ old_position: 7, new_position: 9, schedule_id: 1 })
      new_playlist = db.get_full_playlist(1)
      expect(new_playlist.map { |spin| spin.audio_block_id }).to eq([2,3,1,4])
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
                                         audio_block_id: 375 + i,
                                         airtime: Time.new(1983, 4, 15, 18) + (i*360),
                                         listeners_at_start: 55 + i,
                                         listeners_at_finish: 57 + i,
                                         duration: 500
                                         })
      end
    end

    it 'can be created' do
      expect(@log_entries[0].id).to be_a(Fixnum)
      expect(@log_entries[0].station_id).to eq(4)
      expect(@log_entries[0].current_position).to eq(76)
      expect(@log_entries[0].audio_block_id).to eq(375)
      expect(@log_entries[0].airtime.to_f.floor).to eq(Time.new(1983, 4, 15, 18).to_f.floor)
      expect(@log_entries[0].listeners_at_start).to eq(55)
      expect(@log_entries[0].listeners_at_finish).to eq(57)
      expect(@log_entries[0].duration).to eq(500)
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

    it 'gets a log entry' do
      expect(db.get_log_entry(@log_entries[0].id).current_position).to eq(76)
    end

    it 'can be updated' do
      updated_entry = db.update_log_entry({ id: @log_entries[0].id,
                                          listeners_at_start: 0,
                                          listeners_at_finish: 0,
                                          })
      entry = db.get_log_entry(@log_entries[0].id)
      expect(entry.id).to eq(updated_entry.id)
      expect(entry.listeners_at_finish).to eq(0)
      expect(entry.listeners_at_start).to eq(0)
    end

    it 'destroys all log_entries' do
      db.destroy_all_log_entries
      expect(PL.db.get_recent_log_entries({ station_id: 4, count:15}).size).to eq(0)
    end

    it 'can tell if a log exists' do
      expect(db.log_exists?(4)).to eq(true)
      db.destroy_all_log_entries
      expect(db.log_exists?(4)).to eq(false)
    end
  end

  ###############
  #  Schedules  #
  ###############
  describe 'Schedules' do

    before(:each) do
      db.clear_everything
      @schedule = db.create_schedule({ station_id: 9 })
    end

    it 'creates a schedule' do
      expect(@schedule.id).to be_a(Fixnum)
      expect(@schedule.station_id).to eq(9)
    end

    it 'can be updated' do
      updated_schedule = db.update_schedule({ id: @schedule.id,
                                              station_id: 1,
                                              current_playlist_end_time: Time.local(2014,1,1),
                                              original_playlist_end_time: Time.local(2014,1,2),
                                              next_commercial_block_id: 8,
                                              last_accurate_current_position: 100 })
      expect(updated_schedule.station_id).to eq(1)
      expect(updated_schedule.current_playlist_end_time.to_s).to eq('2014-01-01 00:00:00 -0600')
      expect(updated_schedule.original_playlist_end_time.to_s).to eq('2014-01-02 00:00:00 -0600')
      expect(updated_schedule.next_commercial_block_id).to eq(8)
      expect(updated_schedule.last_accurate_current_position).to eq(100)
    end

    it 'can be gotten' do
      gotten_schedule = db.get_schedule(@schedule.id)
      expect(gotten_schedule.id).to eq(@schedule.id)
    end

    it 'can be deleted' do
      deleted_schedule = db.delete_schedule(@schedule.id)
      expect(db.get_schedule(@schedule.id)).to be_nil
      expect(deleted_schedule.station_id).to eq(9)
    end

    it 'deletes all schedules' do
      db.destroy_all_schedules
      expect(db.get_schedule(@schedule.id)).to be_nil
    end
  end

  ##############
  #  Sessions  #
  ##############
  describe 'Session' do
    it 'creates a Session' do
      user = db.create_user({ twitter: 'jimmy' })
      session_id = db.create_session(user.id)
      user_id = db.get_uid_by_sid(session_id)
      expect(user_id).to eq(user.id)
      expect(db.get_uid_by_sid("999999")).to be_nil
    end

    it 'gets a session_id from uid' do
      session_id = db.create_session(1)
      expect(db.get_sid_by_uid(1)).to eq(session_id)
      expect(db.get_sid_by_uid(9999)).to be_nil      
    end

    it 'gets a uid from a session_id' do
      session_id = db.create_session(1)
      expect(db.get_uid_by_sid(session_id)).to eq(1)
      expect(db.get_uid_by_sid('999')).to be_nil
    end

    it 'deletes a session' do
      session_id = db.create_session(5)
      expect(db.get_uid_by_sid(session_id)).to eq(5)
      db.delete_session(session_id)
      expect(db.get_uid_by_sid(session_id)).to be_nil
    end
  end
end