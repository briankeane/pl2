require 'spec_helper'
require 'aws-sdk'
require 'mp3info'

describe 'audio_file_storage_handler' do

  before(:all) do
    @s3 = AWS::S3.new
    @grabber = PL::AudioFileStorageHandler.new
    @s3.buckets['playolasongstest'].objects.delete_all
  end

  it 'grabs song audio' do
    VCR.use_cassette('audio_file_storage_handler/grabsong') do
      song_file = File.open('spec/test_files/stepladder.mp3')
      song_file.binmode
      @s3.buckets[S3['SONGS_BUCKET']].objects['_pl_0000001_Rachel Loy_Stepladder.mp3'].write(:file => song_file)
      song_file.close

      song = PL.db.create_song({ artist: 'Rachel Loy',
                          album: 'Broken Machine',
                          title: "Stepladder",
                          key: '_pl_0000001_Rachel Loy_Stepladder.mp3' })

      mp3_file = @grabber.grab_audio(song)

      mp3 = ''
      Mp3Info.open(mp3_file) do |song_tags|
        mp3 = song_tags
      end

      expect(mp3.tag.title).to eq('Stepladder')
      expect(mp3.tag.album).to eq('Broken Machine')
      expect(mp3.tag.artist).to eq('Rachel Loy')
      expect(mp3_file.size).to eq(4589616)
    end
  end

  it 'grabs commentary audio' do
    VCR.use_cassette('audio_file_storage_handler/grabcommentary') do
      commentary_file = File.open('spec/test_files/testCommentary.mp3')
      commentary_file.binmode
      @s3.buckets[S3['COMMENTARIES_BUCKET']].objects['testCommentary.mp3'].write(:file => commentary_file)
      commentary_file.close

      commentary = PL.db.create_commentary({ station_id: 1,
                                            key: 'testCommentary.mp3' })

      mp3_file = @grabber.grab_audio(commentary)

      expect(mp3_file.size).to eq(497910)
    end
  end

  it 'grabs commercial audio' do
    VCR.use_cassette('audio_file_storage_handler/grabcommercial') do
      commercial_file = File.open('spec/test_files/testCommercial.mp3')
      commercial_file.binmode
      @s3.buckets[S3['COMMERCIALS_BUCKET']].objects['testCommercial.mp3'].write(:file => commercial_file)
      commercial_file.close

      commercial = PL.db.create_commercial({ sponsor: 'test',
                                              key: 'testCommercial.mp3' })
      mp3_file = @grabber.grab_audio(commercial)

      expect(mp3_file.size).to eq(128053)
    end
  end

  it 'gets metadata from a stored song' do
    #VCR.use_cassette('audio_file_storage_handler/getmetadata', :preserve_exact_body_bytes => true) do
      
      song_file = File.open('spec/test_files/stepladder.mp3')
      song_file.binmode
      aws_song = @s3.buckets[S3['SONGS_BUCKET']].objects['_pl_0000001_Rachel Loy_Stepladder.mp3'].write('hi')
      aws_song.metadata[:pl_title] = 'Stepladder'
      aws_song.metadata[:pl_artist] = 'Rachel Loy'
      aws_song.metadata[:pl_album] = 'Broken Machine'
      aws_song.metadata[:pl_duration] = 55
      aws_song.metadata[:pl_echonest_id] = 'SOOWAAV13CF6D1B3FA'

      metadata = @grabber.get_stored_song_metadata('_pl_0000001_Rachel Loy_Stepladder.mp3')
      expect(metadata[:title]).to eq('Stepladder')
      expect(metadata[:artist]).to eq('Rachel Loy')
      expect(metadata[:album]).to eq('Broken Machine')
      expect(metadata[:duration]).to eq(55)
      expect(metadata[:echonest_id]).to eq('SOOWAAV13CF6D1B3FA')

      aws_song.delete
    #end
  end

  it 'stores a song' do
    #VCR.use_cassette('audio_file_storage_handler/storesong', :preserve_exact_body_bytes => true) do
      File.open('spec/test_files/look.mp3') do |file|
        new_key = @grabber.store_song({ title: 'Look At That Girl',
                                        artist: 'Rachel Loy',
                                        album: 'Broken Machine',
                                        duration: 9999,
                                        echonest_id: 'test_echonest_id',
                                        song_file: 'file' })
        
        metadata = @grabber.get_stored_song_metadata(new_key)
        
        expect(metadata[:title]).to eq('Look At That Girl')
        expect(metadata[:artist]).to eq('Rachel Loy')
        expect(metadata[:album]).to eq('Broken Machine')
        expect(metadata[:duration]).to eq(9999)
        expect(metadata[:echonest_id]).to eq('test_echonest_id')
        @grabber.delete_song(new_key)
      end
    #end
  end

  it 'updates the metadata on a song' do
    File.open('spec/test_files/test_uploads.txt') do |file|
      new_key = @grabber.store_song({ title: 'Look At That Girl',
                                        artist: 'Rachel Loy',
                                        album: 'Broken Machine',
                                        duration: 9999,
                                        echonest_id: 'test_echonest_id',
                                        song_file: file })

      @grabber.update_stored_song_metadata({ key: new_key,
                                        artist: 'FAKEartist',
                                        album: 'FAKEalbum',
                                        title: 'FAKEtitle',
                                        duration: 1,
                                        echonest_id: 'FAKEid' })

      metadata = @grabber.get_stored_song_metadata(new_key)

      expect(metadata[:title]).to eq('FAKEtitle')
      expect(metadata[:artist]).to eq('FAKEartist')
      expect(metadata[:album]).to eq('FAKEalbum')
      expect(metadata[:duration]).to eq(1)
      expect(metadata[:echonest_id]).to eq('FAKEid')
      @grabber.delete_song(new_key)
    end
  end

  it 'explicitly sets nil on echonest metadata' do
    File.open('spec/test_files/look.mp3') do |file|
      new_key = @grabber.store_song({ title: 'Look At That Girl',
                                        artist: 'Rachel Loy',
                                        album: 'Broken Machine',
                                        duration: 9999,
                                        echonest_id: 'BLABLABLA',
                                        song_file: file })

      @grabber.update_stored_song_metadata({ key: new_key,
                                        artist: 'FAKEartist',
                                        album: 'FAKEalbum',
                                        title: 'FAKEtitle',
                                        duration: 1,
                                        echonest_id: 'SET_TO_NIL' })

      metadata = @grabber.get_stored_song_metadata(new_key)

      expect(metadata[:echonest_id]).to be_nil
      @grabber.delete_song(new_key)
    end
  end

  xit 'gets unprocessed song audio' do
  end

  it 'deletes unprocessed song' do
    s3 = AWS::S3.new
    song = s3.buckets['playolaunprocessedsongstest'].objects.create('key', 'data')
    song.write('hi')
    @grabber.delete_unprocessed_song('key')
    expect(s3.buckets['playolaunprocessedsongstest'].objects['key'].exists?).to eq(false)
  end

  
  it 'returns an array of all stored songs as objects' do
    all_songs = @grabber.get_all_songs
    expect(all_songs.size).to eq(3)
    expect(all_songs[0].artist).to eq('Rachel Loy')
    expect(all_songs[2].title).to eq('The Grandpa Song')
  end

  it 'deletes a song' do
    File.open('spec/test_files/look.mp3') do |file|
      new_key = @grabber.store_song({ title: 'Look At That Girl',
                                      artist: 'Rachel Loy',
                                      album: 'Broken Machine',
                                      duration: 9999,
                                      echonest_id: 'test_echonest_id',
                                      song_file: file })
      metadata = @grabber.get_stored_song_metadata(new_key)
      expect(metadata[:title]).to eq('Look At That Girl')
      @grabber.delete_song(new_key)
      expect(@grabber.get_stored_song_metadata(new_key)).to be_nil
    end
  end
end