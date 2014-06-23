require 'aws-sdk'
require 'mp3info'

module PL
      class ProcessSong < UseCase
	     def run(key)

			# set up s3
			s3 = AWS::S3.new
			before_processing_bucket = 'playolauploadedsongs'
	    after_processing_bucket = 'playolasongs'

	    s3_song_file = s3.buckets[before_processing_bucket].objects[key]

	    # download the song
	    temp_song_file = Tempfile.new("temp_song_file")

      temp_song_file.open()
      temp_song_file.write(s3_song_file.read)

      # get the id3 tags
      mp3 = ''
      Mp3Info.open(temp_song_file) do |song_tags|
        mp3 = song_tags
      end

      artist = mp3.tag.artist
      title = mp3.tag.title
      album = mp3.tag.album
      duration = (mp3.length * 1000).to_i

      case 
      when !artist || artist.strip.empty?
      	return failure (:no_artist_in_id3_tags)
      when !title || title.strip.empty?
      	return failure (:no_title_in_id3_tags)
      when !album || album.strip.empty?
      	return failure (:no_album_in_id3_tags)
      end

      if PL.db.song_exists?({ title: title,
      												artist: artist,
      												album: album })
     	 	s3_song_file.delete
      	return failure(:song_already_exists)
      end


      #create the song object and add it to the db
      song = PL.db.create_song({ title: title,
      														artist: artist,
      														album: album,
      														duration: duration
      													})

      new_key = (('0' * (5 - song.id.to_s.size)) +  song.id.to_s + '_' + song.artist + '_' + song.title + '.' + '.mp3')
      s3.buckets[after_processing_bucket].objects[new_key].write(:file => temp_song_file)

      # store metadata
      aws_song_object = s3.buckets[after_processing_bucket].objects[new_key]
      aws_song_object.metadata[:pl_title] = title
      aws_song_object.metadata[:pl_artist] = artist
      aws_song_object.metadata[:pl_album] = album
      aws_song_object.metadata[:pl_duration] = duration

      song = PL.db.update_song({ id: song.id, key: new_key })

      # delete pre-processing file
      s3_song_file.delete

      return success :song => song
		end
	end
end