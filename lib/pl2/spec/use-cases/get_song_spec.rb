require 'spec_helper'

describe 'GetSong' do
  it 'calls bullshit if the song does not exist' do
    result = PL::GetSong.run(999)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:song_not_found)
  end

  it 'gets a song' do
    song = PL.db.create_song({ title: 'Stepladder',
                            artist: 'Rachel Loy',
                            album: 'Broken Machine',
                            duration: 10 })

    result = PL::GetSong.run(song.id)
    expect(result.success?).to eq(true)
    expect(result.song.id).to eq(song.id)
    expect(result.song.title).to eq('Stepladder')
    expect(result.song.artist).to eq('Rachel Loy')
    expect(result.song.album).to eq('Broken Machine')
    expect(result.song.duration).to eq(10)
  end
end