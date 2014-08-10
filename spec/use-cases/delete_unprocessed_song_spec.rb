require 'spec_helper'

require 'aws-sdk'

describe 'DeleteUnprocessedSong' do
  it 'deletes unprocessed song' do
    expect_any_instance_of(PL::AudioFileStorageHandler).to receive(:bucket).at_least(:once).and_return({ songs: 'playolasongstest',
                                                                  commercials: 'playolacommercialstest',
                                                                  commentaries: 'playolacommentariestest',
                                                                  unprocessedsongs: 'playolaunprocessedsongstest' })

    s3 = AWS::S3.new
    song = s3.buckets['playolaunprocessedsongstest'].objects.create('key', 'data')
    song.write('hi')
    result = PL::DeleteUnprocessedSong.run('key')
    expect(result.success?).to eq(true)
    expect(s3.buckets['playolaunprocessedsongstest'].objects['key'].exists?).to eq(false)
  end
end