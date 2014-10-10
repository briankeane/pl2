require 'spec_helper'

describe 'Song' do
  before(:each) do
    @song = PL::Song.new({     id: 1,
                artist: 'Rachel Loy',
                 title: 'Stepladder',
                 album: 'Broken Machine',
              duration: 180000,
                   key: 'ThisIsAKey.mp3',
                   created_at: Time.new(1970),
                   updated_at: Time.new(1970, 1, 2) })
  end
    
  it 'is created with id, artist, title, album, duration, :key' do
    expect(@song.id).to eq(1)
    expect(@song.artist).to eq('Rachel Loy')
    expect(@song.title).to eq('Stepladder')
    expect(@song.album).to eq('Broken Machine')
    expect(@song.duration).to eq(180000)
    expect(@song.key).to eq('ThisIsAKey.mp3')
    expect(@song.created_at).to eq(Time.new(1970))
    expect(@song.updated_at).to eq(Time.new(1970, 1, 2))
  end
end