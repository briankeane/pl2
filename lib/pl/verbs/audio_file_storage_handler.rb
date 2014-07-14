require 'aws-sdk'

module PL
  class AudioFileStorageHandler
    def grab_audio(audio_block)
      case
      when audio_block.is_a?(PL::Song)
        bucket = 'playolasongs'
      when audio_block.is_a?(PL::Commercial)
        bucket = 'playolacommercials'
      when audio_block.is_a?(PL::Commentary)
        bucket = 'playolacommentary'
      end

      s3 = AWS::S3.new

      s3_song_file = s3.buckets[bucket].objects[audio_block.key]
      temp_song_file = Tempfile.new('temp_song_file')
      temp_song_file.open
      temp_song_file.write(s3_song_file.read)
      temp_song_file.close

      return temp_song_file
    end

    def store_song(attrs)
      stored_song_keys = s3.buckets[after_processing_bucket].objects.collect(&:key)

      s3.buckets[after_processing_bucket].objects[new_key].write(:file => temp_song_file)

      aws_song_object = s3.buckets[after_processing_bucket].objects[new_key]
      aws_song_object.metadata[:pl_title] = attrs[:title]
      aws_song_object.metadata[:pl_artist] = attrs[:artist]
      aws_song_object.metadata[:pl_album] = attrs[:album]
      aws_song_object.metadata[:pl_duration] = attrs[:duration]
      aws_song_object.metadata[:pl_echonest_id] = attrs[:echonest_id]
    end

  end
end