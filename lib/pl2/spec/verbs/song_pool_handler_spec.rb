require 'spec_helper'

describe 'SongPoolHandler' do
  before(:all) do
    @sph = PL::SongPoolHandler.new
    @song1 = PL::Song.new(artist: 'Rachel Loy',
                        title: 'Stepladder',
                        album: 'Broken Machine',
                        duration: 999,
                        key: 'test_key.mp3',
                        echonest_id: 'SOOWAAV13CF6D1B3FA',
                        )
    @song2 = PL::Song.new(artist: 'Rachel Loy',
                        title: 'Cheater',
                        album: 'Broken Machine',
                        duration: 888,
                        key: 'test_key2.mp3',
                        echonest_id: 'SOTWSLV13CF6D275AF',
                        )
    @sph.clear_all_songs
  end

  it 'adds a song to the song pool' do
    VCR.use_cassette('song_pool_handler/add_song') do
      @sph.add_songs(@song1)
      all_songs = @sph.all_songs
      expect(all_songs.size).to eq(1)
      expect(all_songs[0].artist).to eq('Rachel Loy')
      expect(all_songs[0].title).to eq('Stepladder')
      expect(all_songs[0].album).to eq('Broken Machine')
      expect(all_songs[0].duration).to eq(999)
      expect(all_songs[0].key).to eq('test_key.mp3')
      expect(all_songs[0].echonest_id).to eq('SOOWAAV13CF6D1B3FA')
    end
  end

  it 'adds multiple songs to the song pool' do
    VCR.use_cassette('song_pool_handler/add_multiple_songs') do
      @sph.add_songs(@song1, @song2)
      all_songs = @sph.all_songs
      expect(all_songs.size).to eq(2)
      expect(all_songs[0].title).to eq(@song1.title)
      expect(all_songs[1].title).to eq(@song2.title)
    end
  end

  it 'deletes a song from the song pool' do
    VCR.use_cassette('song_pool_handler/delete_song') do
      @sph.add_songs(@song1, @song2)
      @sph.delete_song(@song1.key)
      all_songs = @sph.all_songs
      expect(all_songs.size).to eq(1)
      expect(all_songs[0].title).to_not eq('Stepladder')
    end
  end

  it 'retrieves an array of all songs in the song pool' do
    VCR.use_cassette('song_pool_handler/retrieve_songs') do
      @sph.add_songs(@song1, @song2)
      all_songs = @sph.all_songs
      expect(all_songs.size).to eq(2)
      expect(all_songs[0].title).to eq(@song1.title)
      expect(all_songs[1].title).to eq(@song2.title)
    end
  end

  xit 'clears all songs from the song pool' do
    VCR.use_cassette('song_pool_handler/clear_all_songs') do
      @sph.clear_all_songs
    end
  end

  it 'can tell if a song is included in the pool' do
    VCR.use_cassette('song_pool_handler/song_inclusion_search') do
      expect(@sph.song_included?({ title: 'Stepladder', artist: 'Rachel Loy' })).to eq(false)

      @sph.add_songs(@song1)

      expect(@sph.song_included?({ title: 'Stepladder', artist: 'Rachel Loy' })).to eq(true)
    end
  end


  after(:each) do
    @sph.clear_all_songs
  end

end