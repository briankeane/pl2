require 'spec_helper'

describe 'audio_converter' do
  before(:all) do
    @ac = PL::AudioConverter.new
  end

  it 'converts from wav to mp3' do
    mp3_file_path = @ac.wav_to_mp3('spec/test_files/stepladderwav.wav')
    expect(mp3_file_path).to eq('spec/test_files/stepladderwav.mp3')
    expect(File.exists?(mp3_file_path)).to eq(true)
    File.delete(mp3_file_path) if File.exists?(mp3_file_path)
  end

  it 'converts from mp3 to wav' do
    wav_file_path = @ac.mp3_to_wav('spec/test_files/stepladdermp3.mp3')
    expect(wav_file_path).to eq('spec/test_files/stepladdermp3.wav')
    expect(File.exists?(wav_file_path)).to eq(true)
    File.delete(wav_file_path) if File.exists?(wav_file_path)
  end
end