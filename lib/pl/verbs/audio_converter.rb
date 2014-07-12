module PL
  class AudioConverter
    def mp3_to_wav(mp3_file_path)
      new_file_path =  mp3_file_path.gsub(".mp3", ".wav")
      system("mpg123 -w " + new_file_path + " " + mp3_file_path)
      return new_file_path
    end

    def wav_to_mp3(wav_file_path)
      new_file_path = wav_file_path.gsub(".wav", ".mp3")
      system("lame -V2 -f " + wav_file_path + " " + new_file_path)
      return new_file_path
    end
  end
end