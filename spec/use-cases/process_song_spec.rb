require 'spec_helper'
require 'aws-sdk'

describe 'process_song' do
	before(:each) do
		PL.db.clear_everything
	end

	it 'calls bullshit if no title found' do
		VCR.use_cassette('process_song/no_title') do
			# upload the file to be used
			key = 'mine_no_title.mp3'
			file_name = 'spec/test_files/mine_no_title.mp3'
			s3 = AWS::S3.new
			upload_bucket = 'playolauploadedsongs'
			s3.buckets[upload_bucket].objects[key].write(:file => file_name)

			result = PL::ProcessSong.run('mine_no_title.mp3')
			expect(result.success?).to eq(false)
			expect(result.error).to eq(:no_title_in_id3_tags)
		end
	end

	it 'calls bullshit if no artist found' do
		VCR.use_cassette('process_song/no_artist') do
			key = 'mine_no_artist.mp3'
			file_name = 'spec/test_files/mine_no_artist.mp3'
			s3 = AWS::S3.new
			upload_bucket = 'playolauploadedsongs'
			s3.buckets[upload_bucket].objects[key].write(:file => file_name)

			result = PL::ProcessSong.run('mine_no_artist.mp3')
			expect(result.success?).to eq(false)
			expect(result.error).to eq(:no_artist_in_id3_tags)
		end
	end

	it 'calls bullshit if no album found' do
		VCR.use_cassette('process_song/no_album') do
			key = 'mine_no_album.mp3'
			file_name = 'spec/test_files/mine_no_album.mp3'
			s3 = AWS::S3.new
			upload_bucket = 'playolauploadedsongs'
			s3.buckets[upload_bucket].objects[key].write(:file => file_name)

			result = PL::ProcessSong.run('mine_no_album.mp3')
			expect(result.success?).to eq(false)
			expect(result.error).to eq(:no_album_in_id3_tags)
		end
	end

	it 'does not add a song already in the library' do
		VCR.use_cassette('process_song/good_request') do
			PL.db.create_song({ artist: 'Brian Keane',
													album: '90 Miles an Hour',
													title: "03 Tractors Ain't Sexy",
													duration: 5 })
			key = 'mine.mp3'
			file_name = 'spec/test_files/mine.mp3'
			s3 = AWS::S3.new
			upload_bucket = 'playolauploadedsongs'
			s3.buckets[upload_bucket].objects[key].write(:file => file_name)

			result = PL::ProcessSong.run('mine.mp3')
			expect(result.success?).to eq(false)
			expect(result.error).to eq(:song_already_exists)
		end		
	end

	it 'processes a song and adds it to the library' do
		VCR.use_cassette('process_song/good_request2') do
			key = 'mine.mp3'
			file_name = 'spec/test_files/mine.mp3'
			s3 = AWS::S3.new
			upload_bucket = 'playolauploadedsongs'
			s3.buckets[upload_bucket].objects[key].write(:file => file_name)

			result = PL::ProcessSong.run('mine.mp3')

			expect(result.success?).to eq(true)
			expect(result.song.title).to eq("03 Tractors Ain't Sexy")
			expect(result.song.artist).to eq('Brian Keane')
			expect(result.song.album).to eq('90 Miles an Hour')
		end
	end
end