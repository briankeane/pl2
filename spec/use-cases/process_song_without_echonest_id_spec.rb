require 'spec_helper'
require 'aws-sdk'

describe 'process_song_without_echonest_id' do

  it 'does not add a song already in the library' do
    VCR.use_cassette('process_song/already_in_library') do
      PL.db.create_song({ artist: 'Brian Keane',
                          album: '90 Miles an Hour',
                          title: "03 Tractors Ain't Sexy",
                          duration: 5 })
      key = 'mine.mp3'
      filename = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)

      result = PL::ProcessSongWithoutEchonestId.run({ key: 'mine.mp3' })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:song_already_exists)
    end   
  end
  

  it 'processes a song and adds it to the library' do
    VCR.use_cassette('process_song_without_echonest_id/good_request') do
      key = 'mine.mp3'
      filename = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      upload_bucket = 'playolaunprocessedsongs'
      s3.buckets[S3['UNPROCESSED_SONGS']].objects[key].write(:file => filename)

      result = PL::ProcessSongWithoutEchonestId.run({ key: 'mine.mp3',
                                                      artist: 'artistbla',
                                                      album: 'albumbla',
                                                      title: 'titlebla' })
      expect(result.success?).to eq(true)
      expect(result.song.title).to eq("titlebla")
      expect(result.song.artist).to eq('artistbla')
      expect(result.song.album).to eq('albumbla')
    end
  end

  after(:all) do
    s3 = AWS::S3.new
    bucket = s3.buckets[S3['UNPROCESSED_SONGS']]
    bucket.objects['mine.mp3'].delete unless !bucket.objects['mine.mp3'].exists?
  end

end

