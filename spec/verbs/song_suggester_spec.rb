require 'spec_helper'

describe 'song_suggester' do
  before do
    @ss = PL::SongSuggester.new
  end

  it 'suggests a playlist based on 1 artist' do
    playlist = @ss.get_suggestions('Rachel Loy')
    expect(playlist.size).to eq(100)
    expect(playlist[50][:title]).to be_a(String)
    expect(playlist[75][:artist]).to be_a(String)
  end

  it 'suggests a playlist based on 5 artists' do
    playlist = @ss.get_suggestions('Rachel Loy', 'Lily Allen', 'Miranda Lambert', 'Charlie Worsham', 'Will Hoge')
    expect(playlist.size).to eq(100)
    expect(playlist[50][:title]).to be_a(String)
    expect(playlist[75][:artist]).to be_a(String)
  end

  after do
    ss = nil
  end

end