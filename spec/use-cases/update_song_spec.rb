require 'spec_helper'

describe 'UpdateSong' do
  it 'calls bullshit if the song is not found' do
    result = PL::UpdateSong.run({ id: 999,
                                  artist: 'Bob' })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:song_not_found)
  end

  it 'updates a song' do
    song = PL.db.create_song({ artist: 'Brian Keane',
                        title: 'Bar Lights',
                        album: 'Coming Home',
                        duration: 19000,
                        key: 'ThisIsAKey.mp3' })

    result = PL::UpdateSong.run({ id: song.id, artist: 'Bob',
                                    title: 'Song By Bob',
                                    album: 'Album By Bob',
                                    duration: 20000,
                                    key: 'BobsKey.mp3'
                                })

    expect(result.success?).to eq(true)
    expect(result.song.artist).to eq('Bob')
    expect(result.song.title).to eq('Song By Bob')
    expect(result.song.album).to eq('Album By Bob')
    expect(result.song.duration).to eq(20000)
    expect(result.song.key).to eq('BobsKey.mp3')
    end
end