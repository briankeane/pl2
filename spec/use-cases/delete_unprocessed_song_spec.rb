require 'spec_helper'

require 'aws-sdk'

describe 'DeleteUnprocessedSong' do
  it 'deletes unprocessed song' do
    s3 = AWS::S3.new
    song = s3.buckets[S3['SONGS_BUCKET']].objects.create('key', 'data')
    song.write('hi')
    result = PL::DeleteUnprocessedSong.run('key')
    expect(result.success?).to eq(true)
    expect(s3.buckets['playolaunprocessedsongstest'].objects['key'].exists?).to eq(false)
  end
end