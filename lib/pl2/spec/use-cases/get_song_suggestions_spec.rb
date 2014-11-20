require 'spec_helper'
require 'echowrap'

describe 'GetSongSuggestions' do
  before(:each) do
    @ss = PL::SongSuggester.new
    @sp = PL::SongPoolHandler.new
  end

  it 'takes in artists and returns a list of available songs' do
    VCR.use_cassette('song_suggester/GetSongSuggestions') do

      # preload catalogue and echonest_data
      data = ''
      File.open('spec/test_files/echonest_cat.json','r') { |f| data = f.read }
      Echowrap.taste_profile_update(id: ECHONEST_KEYS['TASTE_PROFILE_ID'], data: data)
      
      all_songs = @sp.all_songs
      puts "Adding songs from echonest...."
      all_songs.each_with_index do |song, i|
        print "\rAdding song #{i + 1} of #{all_songs.count}" 
        PL.db.create_song({ title: song.title,
                            artist: song.artist,
                            album: song.album,
                            key: song.key,
                            duration: song.duration,
                            echonest_id: song.echonest_id })
      end

      result = PL::GetSongSuggestions.run(['Bob Dylan', 'Rachel Loy', 'Billy Gillman'])
      expect(result.success?).to eq(true)
      expect(result[:song_suggestions].size > 40).to eq(true)
    end
  end
end