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
      pretrim_file_path = wav_file_path.gsub(".wav", "pretrim.mp3")
      new_file_path = wav_file_path.gsub(".wav", ".mp3")


      # provide a different name if wav is not specified
      if new_file_path == wav_file_path
        new_file_path = new_file_path + '.mp3'
        pretrim_file_path = new_file_path + 'pretrim.mp3'
      end

      #convert file
      system("lame -V2 -f " + wav_file_path + " " + pretrim_file_path)
      
      #trim silence from beginning and end
      system("sox " + pretrim_file_path + " " + new_file_path + " silence 1 0.1 0.1% reverse silence 1 0.1 0.1% reverse")
      return new_file_path
    end
  end
end