require 'spec_helper'

describe 'song_suggester' do
  before do
    @ss = PL::SongSuggester.new
  end

  it 'suggests a playlist based on 1 artist' do
    playlist = @ss.get_suggestions('Rachel Loy')
    expect(playlist.size > 0).to eq(true)
    expect(playlist[0].title).to be_a(String)
    expect(playlist[0].artist).to be_a(String)
  end

  it 'suggests a playlist based on 5 artists' do
    playlist = @ss.get_suggestions('Rachel Loy', 'Lily Allen', 'Miranda Lambert', 'Charlie Worsham', 'Will Hoge')
    expect(playlist.size > 0).to eq(true)
    expect(playlist[0][:title]).to be_a(String)
    expect(playlist[0][:artist]).to be_a(String)
  end

  after do
    ss = nil
  end

end