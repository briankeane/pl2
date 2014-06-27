require 'spec_helper'
require 'aws-sdk'
require 'mp3info'

describe 'audio_file_grabber' do
  it 'grabs song audio' do
    VCR.use_cassette('audio_file_grabber/grabsong') do
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
    end
  end

  it 'grabs commentary audio' do
    VCR.use_cassette('audio_file_grabber/grabcommentary') do
      commentary = PL.db.create_commentary({ station_id: 1,
                                            key: 'testCommentary.mp3' })

      grabber = PL::AudioFileGrabber.new

      mp3_file = grabber.grab_audio(commentary)

      expect(mp3_file.size).to eq(497910)
    end
  end

  it 'grabs commercial audio' do
    VCR.use_cassette('audio_file_grabber/grabcommercial') do
      commercial = PL.db.create_commercial({ sponsor: 'test',
                                              key: 'testCommercial.mp3' })
      grabber = PL::AudioFileGrabber.new
      mp3_file = grabber.grab_audio(commercial)

      expect(mp3_file.size).to eq(128053)
    end

  end




end