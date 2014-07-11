require 'spec_helper'

describe 'SongProcessor' do
  before(:all) do
    @sp = PL::SongProcessor.new
  end

  xit 'adds a song to the system (db, AWS, and EchoNest)' do
  end

  it 'gets the id3 tags from an mp3 file' do
    file = File.open('spec/test_files/stepladder.mp3', 'r')
    tags = @sp.get_id3_tags(file)
    expect(tags[:artist]).to eq('Rachel Loy')
    expect(tags[:title]).to eq('Stepladder')
    expect(tags[:album]).to eq('Broken Machine')
    expect(tags[:duration]).to eq(222223)
  end

  it 'gets the echowrap info' do
    song = @sp.get_echo_nest_info({ title: 'Stepladder', artist: 'Rachel Loy' })
  end


  after(:all) do
    @sp = nil
  end

end