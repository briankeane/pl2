require 'aws-sdk'

module PL
  class AudioFileGrabber
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
      temp_song_file.open()
      temp_song_file.write(s3_song_file.read)

      return temp_song_file
    end

  end
end