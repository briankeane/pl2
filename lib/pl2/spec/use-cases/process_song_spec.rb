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
      expect(result.error).to eq(:no_title_in_tags)
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
      expect(result.error).to eq(:no_artist_in_tags)
    
    end
  end

  it 'does not add a song already in the library' do
    VCR.use_cassette('process_song/song_in_library') do
      song = PL.db.create_song({ artist: 'Brian Keane',
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
      expect(result.song.id).to eq(song.id)
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
      expect(result.tags).to_not be_nil
      expect(result.echonest_info).to_not be_nil
    end
  end

  it 'processes an mp3 and adds it to the library' do
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

  it 'processes an m4a and adds it to the library' do
    VCR.use_cassette('process_song/m4a_good_request') do
      key = 'lonestar.m4a'
      filename = 'spec/test_files/lonestar.m4a'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)
      result = PL::ProcessSong.run('lonestar.m4a')

      expect(result.success?).to eq(true)
      expect(result.song.title).to eq('Lone Star Blues')
      expect(result.song.artist).to eq('Delbert McClinton')
      expect(result.song.album).to eq('Room to Breathe')
    end
  end

  it 'calls bullshit if an m4a is copy-protected' do
    VCR.use_cassette('process_song/m4a_encrypted') do
      s3 = AWS::S3.new
      key = 'downtown.m4p'
      filename = 'spec/test_files/downtown.m4p'
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)
      result = PL::ProcessSong.run('downtown.m4p')
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:file_is_encrypted)
    end
  end

  after(:all) do
    s3 = AWS::S3.new
    bucket = s3.buckets[S3['UNPROCESSED_SONGS']]
    bucket.objects['mine.mp3'].delete unless !bucket.objects['mine.mp3'].exists?
    bucket.objects['mine_no_artist.mp3'].delete unless !bucket.objects['mine_no_artist.mp3'].exists?
    bucket.objects['mine_no_title.mp3'].delete unless !bucket.objects['mine_no_title.mp3'].exists?
    bucket.objects['stepladder.mp3'].delete unless !bucket.objects['stepladder.mp3'].exists?
    bucket.objects['downtown.m4p'].delete unless !bucket.objects['downtown.m4p'].exists?
  end


end