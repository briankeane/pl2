require 'spec_helper'

describe 'SongProcessor' do
  before(:each) do
    @song_processor = PL::SongProcessor.new
    @song_pool = PL::SongPoolHandler.new

    PL.db.clear_everything
    @song_pool.clear_all_songs

  end

  it 'adds a song to the system (db, AWS, and EchoNest)' do

    File.open('spec/test_files/even_mp3.mp3') do |mp3_file|
      song = @song_processor.add_song_to_system(mp3_file)
      expect(song.title).to eq('Even If It Breaks Your Heart')
      echonest_info = @song_processor.get_echo_nest_info(artist: 'Will Hoge', title: 'Even If It Breaks Your Heart')
      expect(echonest_info[:echonest_id]).to eq('SOVJNMJ142453276BB')
      expect(song.echonest_id).to eq('SOVJNMJ142453276BB')

      song = @song_pool.all_songs.select { |x| x.key == song.key }

      expect(song.size > 0).to eq(true)

    end
  end

  it 'gets the id3 tags from an mp3 file' do
    file = File.open('spec/test_files/stepladder.mp3', 'r')
    tags = @song_processor.get_id3_tags(file)
    expect(tags[:artist]).to eq('Rachel Loy')
    expect(tags[:title]).to eq('Stepladder')
    expect(tags[:album]).to eq('Broken Machine')
    expect(tags[:duration]).to eq(222223)
  end

  it 'gets the echowrap info' do
    song = @song_processor.get_echo_nest_info({ title: 'Stepladder', artist: 'Rachel Loy' })
    expect(song[:title]).to eq('Stepladder')
    expect(song[:echonest_id]).to eq('SOOWAAV13CF6D1B3FA')
    expect(song[:artist]).to eq('Rachel Loy')
  end

  it 'gets possible song matches' do
    matches = @song_processor.get_song_match_possibilities({ artist: 'Rachel Loy',
                                                              title: 'Stepladder' })
    expect(matches.size).to eq(10)
    expect(matches[0][:artist]).to be_a(String)
    expect(matches[0][:title]).to be_a(String)
    expect(matches[0][:echonest_id]).to be_a(String)
  end

end