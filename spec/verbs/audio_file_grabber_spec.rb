require 'spec_helper'
require 'aws-sdk'
require 'mp3info'

describe 'audio_file_grabber' do
  it 'grabs a song' do
    #VCR.use_cassette('audio_file_grabber/grabsong') do
      song = PL.db.create_song({ artist: 'Rachel Loy',
                          album: 'Broken Machine',
                          title: "Good Side",
                          key: '00001_Rachel Loy_Good Side.mp3' })

      grabber = PL::AudioFileGrabber.new

      mp3_file = grabber.grab_audio(song)

      mp3 = ''
      Mp3Info.open(mp3_file) do |song_tags|
        mp3 = song_tags
      end

      expect(mp3.tag.title).to eq('Good Side')
      expect(mp3.tag.album).to eq('Broken Machine')
      expect(mp3.tag.artist).to eq('Rachel Loy')
      expect(mp3_file.size).to eq(4895773)
    #end
  end
end