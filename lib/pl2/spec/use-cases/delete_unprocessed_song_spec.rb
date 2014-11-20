require 'spec_helper'
require 'aws-sdk'

describe 'DeleteUnprocessedSong' do
  before(:each) do
    @s3 = AWS::S3.new
    @grabber = PL::AudioFileStorageHandler.new
    @s3.buckets['playolaunprocessedsongstest'].objects.delete_all
  end    

  it 'calls bullshit if the unprocessed song does not exist' do
    result = PL::DeleteUnprocessedSong.run('asdfsadfasdffasd')
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:unprocessed_song_not_found)
  end

  it 'deletes unprocessed song' do
    s3 = AWS::S3.new
    song = s3.buckets['playolaunprocessedsongstest'].objects.create('key', 'data')
    song.write('hi')
    result = PL::DeleteUnprocessedSong.run('key')
    expect(result.success?).to eq(true)
    expect(s3.buckets['playolaunprocessedsongstest'].objects['key'].exists?).to eq(false)
  end
  
  after(:each) do
    @s3.buckets['playolaunprocessedsongstest'].objects.delete_all
  end

end