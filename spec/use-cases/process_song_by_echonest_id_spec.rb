require 'spec_helper'
require 'aws-sdk'

describe 'ProcessSongByEchonestId' do

  it 'does not add a song already in the library' do
    #VCR.use_cassette('process_song/good_request') do
      PL.db.create_song({ key: 'fakekey',
                          artist: 'Rachel Loy',
                          title: 'Stepladder',
                          echonest_id: 'SOOWAAV13CF6D1B3FA' })
      result = PL::ProcessSongByEchonestId.run({ key: 'fakeky',
                                              echonest_id: 'SOOWAAV13CF6D1B3FA'
                                                 })
      expect(result.success?).to eq(false)
      expect(result.error).to eq(:song_already_exists)
    #end   
  end

  describe 'tests with uploading' do
    before(:each) do
      @key = 'mine_no_artist.mp3'
      @file_name = 'spec/test_files/mine_no_artist.mp3'
      @s3 = AWS::S3.new
      @upload_bucket = 'playolaunprocessedsongs'
      @s3.buckets[@upload_bucket].objects[@key].write(:file => @file_name)
    end
    
    it 'adds a song by echonest_id' do
      #VCR.use_cassette('process_song/no_artist') do
        result = PL::ProcessSongByEchonestId.run({ key: 'mine_no_artist.mp3',
                                                  echonest_id: 'SOOWAAV13CF6D1B3FA' })
        expect(result.success?).to eq(true)
        expect(result.song.artist).to eq('Rachel Loy')
        expect(result.song.title).to eq('Stepladder')
        expect(result.song.echonest_id).to eq('SOOWAAV13CF6D1B3FA')
        expect(@s3.buckets[@upload_bucket].objects[@key].exists?).to eq(false)
      
      #end
    end

    after(:each) do
      if !@s3.buckets[@upload_bucket].objects[@key].exists?
        @s3.buckets[@upload_bucket].objects[@key].delete
      end
    end
  end
end