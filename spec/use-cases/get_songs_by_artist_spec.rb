require 'spec_helper'

describe 'song retrieval tests' do

    it 'returns an empty array if no songs in db' do
        result = PL::GetSongsByArtist.run("Brian Keane")
        expect(result.success?).to eq(true)
        expect(result.songs_by_artist).to eq([])
    end

    it 'returns an array of songs by artist' do
    @song1 = PL.db.create_song({ title: "Bar Lights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song2 = PL.db.create_song({ title: "Bar Nights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song3 = PL.db.create_song({ title: "Bar Brights", artist: "Brian Keane", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song4 = PL.db.create_song({ title: "Bar First", artist: "Bob Dylan", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
    @song5 = PL.db.create_song({ title: "Hell", artist: "Bob Dylan", duration: 226000, sing_start: 5000, sing_end: 208000,
                                 audio_id: 2 })
  
    result = PL::GetSongsByArtist.run("Brian Keane")
    expect(result.songs_by_artist.size).to eq(3)
    expect(result.songs_by_artist[0].title).to eq("Bar Brights")
    expect(result.songs_by_artist[2].title).to eq("Bar Nights")
  end
end