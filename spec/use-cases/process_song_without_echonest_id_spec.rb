require 'spec_helper'
require 'aws-sdk'

describe 'process_song_by_echonest_id' do

  it 'does not add a song already in the library' do
    #VCR.use_cassette('process_song/good_request') do
      PL.db.create_song({ artist: 'Brian Keane',
                          album: '90 Miles an Hour',
                          title: "03 Tractors Ain't Sexy",
                          duration: 5 })
      key = 'mine.mp3'
      file_name = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      upload_bucket = 'playolaunprocessedsongs'
      s3.buckets[upload_bucket].objects[key].write(:file => file_name)

      result = PL::ProcessSongWithoutEchonestId.run({ key: 'mine.mp3' })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:song_already_exists)
    #end   
  end
  
  it 'does not add a song already in the library' do
    #VCR.use_cassette('process_song/good_request') do
      PL.db.create_song({ artist: 'Brian Keane',
                          album: '90 Miles an Hour',
                          title: "03 Tractors Ain't Sexy",
                          duration: 5 })
      key = 'mine.mp3'
      file_name = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      upload_bucket = 'playolaunprocessedsongs'
      s3.buckets[upload_bucket].objects[key].write(:file => file_name)

      result = PL::ProcessSong.run('mine.mp3')
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:song_already_exists)
    #end   
  end

  it 'processes a song and adds it to the library' do
    #VCR.use_cassette('process_song/good_request2') do
      key = 'mine.mp3'
      file_name = 'spec/test_files/mine.mp3'
      s3 = AWS::S3.new
      upload_bucket = 'playolaunprocessedsongs'
      s3.buckets[upload_bucket].objects[key].write(:file => file_name)

      result = PL::ProcessSongWithoutEchonestId.run({ key: 'mine.mp3',
                                                      artist: 'artistbla',
                                                      album: 'albumbla',
                                                      title: 'titlebla' })
      expect(result.success?).to eq(true)
      expect(result.song.title).to eq("titlebla")
      expect(result.song.artist).to eq('artistbla')
      expect(result.song.album).to eq('albumbla')
    #end
  end
end

