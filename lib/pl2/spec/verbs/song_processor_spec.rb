require 'spec_helper'

describe 'SongProcessor' do
  before(:each) do
    @song_processor = PL::SongProcessor.new
    @song_pool = PL::SongPoolHandler.new

    PL.db.clear_everything
    @song_pool.clear_all_songs

  end

  it 'adds a song to the system (db, AWS, and EchoNest)' do
    VCR.use_cassette('song_processor/add_song_to_system') do
      File.open('spec/test_files/even_mp3.mp3') do |mp3_file|
        song = @song_processor.add_song_to_system(mp3_file)
        expect(song.title).to eq('Even If It Breaks Your Heart')
        expect(song.album_artwork_url).to eq('http://a1.mzstatic.com/us/r30/Music/99/bf/52/mzi.fokfkzrh.600x600-75.jpg')
        echonest_info = @song_processor.get_echonest_info(artist: 'Will Hoge', title: 'Even If It Breaks Your Heart')
        
        # sometimes echonest answers with duplicate record
        expect((echonest_info[:echonest_id] == 'SOMVIWL131F77DFB4B') || 
                (echonest_info[:echonest_id] == "SOZWILV12A58A7A00C") || 
                (echonest_info[:echonest_id] === 'SOVJNMJ142453276BB')).to eq(true)
        expect((song.echonest_id == 'SOMVIWL131F77DFB4B') || 
              (song.echonest_id == "SOZWILV12A58A7A00C") || 
              (echonest_info[:echonest_id] === 'SOVJNMJ142453276BB')).to eq(true)
        song = @song_pool.all_songs.select { |x| x.key == song.key }
        expect(song.size > 0).to eq(true)
      end
    end
  end

  it 'adds a song to the system without echonest tags' do
    VCR.use_cassette('song_processor/add_song_without_echonest_tags') do
      File.open('spec/test_files/even_mp3.mp3') do |mp3_file|
        song = @song_processor.add_song_to_system_without_echonest_id(mp3_file)
        expect(song.title).to eq('Even If It Breaks Your Heart')
        expect(PL.db.get_song(song.id).artist).to eq('Will Hoge')
      end
    end
  end

  it 'gets the id3 tags from an mp3 file' do
    File.open('spec/test_files/stepladder.mp3', 'r') do |file|
      tags = @song_processor.get_id3_tags(file)
      expect(tags[:artist]).to eq('Rachel Loy')
      expect(tags[:title]).to eq('Stepladder')
      expect(tags[:album]).to eq('Broken Machine')
      expect(tags[:duration]).to eq(222223)
    end
  end

  it 'gets the id4 tags from an encrypted m4a file' do
    File.open('spec/test_files/downtown.m4p') do |file|
      tags = @song_processor.get_id4_tags(file)
      expect(tags[:artist]).to eq('Hayes Carll')
      expect(tags[:album]).to eq('Trouble In Mind')
      expect(tags[:title]).to eq('Girl Downtown')
      expect(tags[:encrypted]).to eq(true)
    end
  end

  it 'gets the id4 tags from a non-encrypted m4a file' do
    File.open('spec/test_files/lonestar.m4a') do |file|
      tags = @song_processor.get_id4_tags(file)
      expect(tags[:artist]).to eq('Delbert McClinton')
      expect(tags[:album]).to eq('Room to Breathe')
      expect(tags[:title]).to eq('Lone Star Blues')
      expect(tags[:encrypted]).to eq(false)
    end
  end

  describe 'write tags' do
    it 'writes the id3 tags to an mp3 file' do
      File.open('spec/test_files/mine_no_title.mp3', 'rb') do |file|
        @song_processor.write_id3_tags( song_file: file, title: 'WASSSUPPP')
      end

      File.open('spec/test_files/mine_no_title.mp3', 'rb') do |file|
        expect(@song_processor.get_id3_tags(file)[:title]).to eq('WASSSUPPP')
      end
    end

    after(:all) do
      file = File.open('spec/test_files/mine_no_title.mp3', 'rb') do |file|
        @song_processor = PL::SongProcessor.new
        @song_processor.write_id3_tags({ song_file: file,
                                          artist: 'Brian Keane',
                                          title: '',
                                          album: '90 Miles an Hour'})
      end
    end
  end

  it 'gets the echowrap info' do
    VCR.use_cassette('song_processor/get_echowrap_info') do
      song = @song_processor.get_echonest_info({ title: 'Stepladder', artist: 'Rachel Loy' })
      expect(song[:title]).to eq('Stepladder')
      expect(song[:echonest_id]).to eq('SOOWAAV13CF6D1B3FA')
      expect(song[:artist]).to eq('Rachel Loy')
      expect(song[:genres]).to eq([])

      song2 = @song_processor.get_echonest_info({ title: 'Kiss Me In The Dark', artist: 'Randy Rogers' })
      expect((song2[:title] == 'Kiss Me in the Dark') || 
              song2[:title] == 'Kiss Me In The Dark').to eq(true)
      expect(song2[:artist]).to eq('Randy Rogers Band')
      expect(song2[:genres]).to eq(['texas country', 'outlaw country'])
    end
  end

  it 'gets the echonest info by echonest id' do
    VCR.use_cassette('song_processor/get_echonest_info_by_echonest_id') do
      song = @song_processor.get_echonest_info_by_echonest_id('SOOWAAV13CF6D1B3FA')
      expect(song[:title]).to eq('Stepladder')
      expect(song[:artist]).to eq('Rachel Loy')
    end
  end

  it 'returns nil if there is no info by echonest id' do
    VCR.use_cassette('song_processor/return_nil_if_no_info_by_echonest_id') do
      song = @song_processor.get_echonest_info_by_echonest_id('FAKEECHONESTID')
      expect(song).to be_nil
    end
  end

  it 'gets possible song matches' do
    VCR.use_cassette('song_processor/get_possible_song_matches') do
      matches = @song_processor.get_song_match_possibilities({ artist: 'Rachel Loy',
                                                                title: 'Stepladder' })
      expect(matches.size).to eq(10)
      expect(matches[0][:artist]).to be_a(String)
      expect(matches[0][:title]).to be_a(String)
      expect(matches[0][:echonest_id]).to be_a(String)
    end
  end

  it 'gets album artwork link' do
    match = @song_processor.get_album_artwork_link({ artist: 'Miranda Lambert',
                                                      title: 'Little Red Wagon' })
    expect(match).to eq('http://a1.mzstatic.com/us/r30/Music/v4/e5/22/a0/e522a052-63eb-d71e-7fbd-ccff670a399d/886444518710.600x600-75.jpg')

  end
end