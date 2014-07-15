require 'spec_helper'
require 'aws-sdk'
require 'mp3info'

describe 'audio_file_storage_handler' do
  before(:each) do
    # use test buckets
    expect_any_instance_of(PL::AudioFileStorageHandler).to receive(:bucket).at_least(:once).and_return({ songs: 'playolasongstest',
                                                                  commercials: 'playolacommercialstest',
                                                                  commentaries: 'playolacommentariestest' })
    @grabber = PL::AudioFileStorageHandler.new

  end

  it 'grabs song audio' do
    VCR.use_cassette('audio_file_storage_handler/grabsong') do
      song = PL.db.create_song({ artist: 'Rachel Loy',
                          album: 'Broken Machine',
                          title: "Stepladder",
                          key: '_pl_0000001_Rachel Loy_Stepladder.mp3' })

      mp3_file = @grabber.grab_audio(song)

      mp3 = ''
      Mp3Info.open(mp3_file) do |song_tags|
        mp3 = song_tags
      end

      expect(mp3.tag.title).to eq('Stepladder')
      expect(mp3.tag.album).to eq('Broken Machine')
      expect(mp3.tag.artist).to eq('Rachel Loy')
      expect(mp3_file.size).to eq(4589616)
    end
  end

  it 'grabs commentary audio' do
    VCR.use_cassette('audio_file_storage_handler/grabcommentary') do
      commentary = PL.db.create_commentary({ station_id: 1,
                                            key: 'testCommentary.mp3' })

      mp3_file = @grabber.grab_audio(commentary)

      expect(mp3_file.size).to eq(497910)
    end
  end

  it 'grabs commercial audio' do
    VCR.use_cassette('audio_file_storage_handler/grabcommercial') do
      commercial = PL.db.create_commercial({ sponsor: 'test',
                                              key: 'testCommercial.mp3' })
      mp3_file = @grabber.grab_audio(commercial)

      expect(mp3_file.size).to eq(128053)
    end
  end

  it 'gets metadata from a stored song' do
    VCR.use_cassette('audio_file_storage_handler/getmetadata', :preserve_exact_body_bytes => true) do
      metadata = @grabber.get_stored_song_metadata('_pl_0000001_Rachel Loy_Stepladder.mp3')
      expect(metadata[:title]).to eq('Stepladder')
      expect(metadata[:artist]).to eq('Rachel Loy')
      expect(metadata[:album]).to eq('Broken Machine')
      expect(metadata[:duration]).to eq(55)
      expect(metadata[:echonest_id]).to eq('SOOWAAV13CF6D1B3FA')
    end

  end

  it 'stores a song' do
    VCR.use_cassette('audio_file_storage_handler/storesong', :preserve_exact_body_bytes => true) do
      File.open('spec/test_files/look.mp3') do |file|
        new_key = @grabber.store_song({ title: 'Look At That Girl',
                                        artist: 'Rachel Loy',
                                        album: 'Broken Machine',
                                        duration: 9999,
                                        echonest_id: 'test_echonest_id',
                                        song_file: file })
        
        metadata = @grabber.get_stored_song_metadata(new_key)
        
        expect(metadata[:title]).to eq('Look At That Girl')
        expect(metadata[:artist]).to eq('Rachel Loy')
        expect(metadata[:album]).to eq('Broken Machine')
        expect(metadata[:duration]).to eq(9999)
        expect(metadata[:echonest_id]).to eq('test_echonest_id')
      end
      
    end
  end





end