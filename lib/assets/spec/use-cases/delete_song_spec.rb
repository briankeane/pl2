require 'spec_helper'

describe 'DeleteSong' do  
  it 'calls bullshit if the song does not exist' do
    result = PL::DeleteSong.run(20)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:song_not_found)
  end

  it 'deletes a song' do
    song = PL.db.create_song({ artist: 'Brian Keane' })
    result = PL::DeleteSong.run(song.id)
    expect(result.success?).to eq(true)
    expect(result.deleted_song.artist).to eq('Brian Keane')
  end
end