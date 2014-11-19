module PL
  class AudioConverter
    def mp3_to_wav(mp3_file_path)
      new_file_path =  mp3_file_path.gsub(".mp3", ".wav")

      # proved a different name if mp3 is not specified
      if new_file_path == mp3_file_path
        new_file_path = new_file_path + '.wav'
      end
      system("mpg123 -w " + new_file_path + " " + mp3_file_path)
      return new_file_path
    end

    def wav_to_mp3(wav_file_path)
      new_file_path = wav_file_path.gsub(".wav", ".mp3")

      # provide a different name if wav is not specified
      if new_file_path == wav_file_path
        new_file_path = new_file_path + '.mp3'
      end

      system("lame -V2 -f " + wav_file_path + " " + new_file_path)
      
      return new_file_path
    end
    
    def trim_silence(file_path)
      # grab id3s
      sp = SongProcessor.new
      tags = sp.get_id3_tags(file_path)

      # trim silences
      trimmed_file_path = file_path.gsub('.','trimmed.')
      system('sox ' + file_path + ' ' + trimmed_file_path + ' silence 1 0.1 0.1% reverse silence 1 0.1 0.1% reverse')
      system('cp ' + trimmed_file_path + ' ' + file_path)
      system('rm -rf ' + trimmed_file_path)

      # put the id3s back
      File.open(file_path) do |file|
        tags[:song_file] = file
        sp.write_id3_tags(tags)
      end
    end
  end
end