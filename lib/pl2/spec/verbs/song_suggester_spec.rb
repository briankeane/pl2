require 'spec_helper'

describe 'song_suggester' do
  before(:each) do
    @ss = PL::SongSuggester.new
    @sp = PL::SongPoolHandler.new
  end

  it 'suggests a playlist based on 1 artist' do
    VCR.use_cassette('song_suggester/single_artist_suggest_playlist') do

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

      playlist = @ss.get_suggestions('Rachel Loy')
      expect(playlist.size > 0).to eq(true)
      expect(playlist[0].title).to be_a(String)
      expect(playlist[0].artist).to be_a(String)
    end
  end

  it 'suggests a playlist based on 5 artists' do
    VCR.use_cassette('song_suggester/suggest_playlist') do
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

      playlist = @ss.get_suggestions('Rachel Loy', 'Lily Allen', 'Miranda Lambert', 'Charlie Worsham', 'Will Hoge')
      expect(playlist.size > 30).to eq(true)
      expect(playlist[0].title).to be_a(String)
      expect(playlist[0].artist).to be_a(String)
    end
  end
end