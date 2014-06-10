require 'spec_helper'

describe 'a database' do

	#let(:db) { described_class.new("test") }
	db = PL::Database::InMemory.new

	before { db.clear_everything }

	describe 'a database' do
		before(:each) do
			@user = db.create_user({ twitter: 'BrianKeaneTunes',
							twitter_uid: 756,
							email: 'lonesomewhistle_gmail.com',
							birth_year: 1977,
							gender: 'male' })
		end
		
		it 'creates a user' do
			@user = db.create_user({ twitter: 'BrianKeaneTunes',
									twitter_uid: 756,
									email: 'lonesomewhistle_gmail.com',
									birth_year: 1977,
									gender: 'male' })
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
	end
end