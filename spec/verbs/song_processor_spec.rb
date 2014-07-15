require 'spec_helper'

describe 'SongProcessor' do
  before(:all) do
    @sp = PL::SongProcessor.new
  end

  it 'adds a song to the system (db, AWS, and EchoNest)' do
    File.open('spec/test_files/even_mp3.mp3') do |wav_file|
      expect(@sp.add_song_to_system(wav_file)).to eq(true)
    end
  end

  xit 'gets the id3 tags from an mp3 file' do
    file = File.open('spec/test_files/stepladder.mp3', 'r')
    tags = @sp.get_id3_tags(file)
    expect(tags[:artist]).to eq('Rachel Loy')
    expect(tags[:title]).to eq('Stepladder')
    expect(tags[:album]).to eq('Broken Machine')
    expect(tags[:duration]).to eq(222223)
  end

  it 'gets the echowrap info' do
    song = @sp.get_echo_nest_info({ title: 'Stepladder', artist: 'Rachel Loy' })
    expect(song[:title]).to eq('Stepladder')
    expect(song[:echonest_id]).to eq('SOOWAAV13CF6D1B3FA')
    expect(song[:artist]).to eq('Rachel Loy')
  end


  after(:all) do
    @sp = nil
  end

end