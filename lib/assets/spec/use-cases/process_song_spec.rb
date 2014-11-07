require 'spec_helper'
require 'aws-sdk'

describe 'process_song' do

  it 'calls bullshit if no title found' do
    VCR.use_cassette('process_song/no_title') do
      # upload the file to be used
      key = 'mine_no_title.mp3'
      filename = 'spec/test_files/mine_no_title.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)

      result = PL::ProcessSong.run('mine_no_title.mp3')
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_title_in_id3_tags)
    end
  end

  it 'calls bullshit if no artist found' do
    VCR.use_cassette('process_song/no_artist') do
      key = 'mine_no_artist.mp3'
      filename = 'spec/test_files/mine_no_artist.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)

      result = PL::ProcessSong.run('mine_no_artist.mp3')
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_artist_in_id3_tags)
    
    end
  end

  it 'does not add a song already in the library' do
    VCR.use_cassette('process_song/song_in_library') do
      PL.db.create_song({ artist: 'Brian Keane',
                          album: '90 Miles an Hour',
                          title: "03 Tractors Ain't Sexy",
                          duration: 5 })
      key = 'mine.mp3'
      filename = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)

      result = PL::ProcessSong.run('mine.mp3')
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:song_already_exists)
    end   
  end

  it 'calls bullshit if no echonest match found' do
    VCR.use_cassette('process_song/no_echonest_match') do
      key = 'mine.mp3'
      filename = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)
      result = PL::ProcessSong.run('mine.mp3')

      expect(result.success?).to eq(false)
      expect(result.error).to eq(:no_echonest_match_found)
      expect(result.id3_tags).to_not be_nil
      expect(result.echonest_info).to_not be_nil
    end
  end

  it 'processes a song and adds it to the library' do
    VCR.use_cassette('process_song/good_request') do
      key = 'stepladder.mp3'
      filename = 'spec/test_files/stepladder.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)
      result = PL::ProcessSong.run('stepladder.mp3')

      expect(result.success?).to eq(true)
      expect(result.song.title).to eq("Stepladder")
      expect(result.song.artist).to eq('Rachel Loy')
      expect(result.song.album).to eq('Broken Machine')
    end 
  end

  after(:all) do
    s3 = AWS::S3.new
    bucket = s3.buckets[S3['UNPROCESSED_SONGS']]
    bucket.objects['mine.mp3'] unless !bucket.objects['mine.mp3'].exists?
    bucket.objects['mine.mp3'] unless !bucket.objects['mine_no_artist.mp3'].exists?
    bucket.objects['mine.mp3'] unless !bucket.objects['mine_no_title.mp3'].exists?
    bucket.objects['stepladder.mp3'] unless !bucket.objects['stepladder.mp3'].exists?
  end


end