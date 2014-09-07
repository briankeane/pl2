require 'spec_helper'

  describe 'InsertSpin' do
    before(:each) do
      Timecop.travel(Time.local(2014, 5, 9, 10))
      @user = PL.db.create_user({ twitter: "Bob" })
      @songs = []
      86.times do |i|
        @songs << PL.db.create_song({ title: "#{i} title", artist: "#{i} artist", album: "#{i} album", duration: 190000 })
      end

      # build spins_per_week
      heavy = @songs[0..30]
      medium = @songs[31..65]
      light = @songs[66..85]

      spins_per_week = {}
      heavy.each { |song| spins_per_week[song.id] = PL::HEAVY_ROTATION }
      medium.each { |song| spins_per_week[song.id] = PL::MEDIUM_ROTATION }
      light.each { |song| spins_per_week[song.id] = PL::LIGHT_ROTATION }
      @station = PL.db.create_station({ user_id: @user.id, 
                                          spins_per_week: spins_per_week 
                                       })
      @schedule = PL.db.create_schedule({ station_id: @station.id })
      @schedule.generate_playlist
      @old_playlist_ab_ids = PL.db.get_full_playlist(@schedule.id).map { |spin| spin.audio_block_id }
    end

    it 'adds a spin' do
      added_audio_block = PL.db.create_song({ duration: 50000 })
      result = PL::InsertSpin.run({ schedule_id: @schedule.id,
                                add_position: 15,
                                audio_block_id: added_audio_block.id })

      expect(result.success?).to eq(true)
      new_playlist = PL.db.get_full_playlist(@schedule.id)
      expect(new_playlist.size).to eq(@old_playlist_ab_ids.size + 1)
      expect(result.added_spin.current_position).to eq(15)
      expect(@old_playlist_ab_ids.last).to eq(new_playlist.last.audio_block_id)
      expect(new_playlist[13].audio_block_id).to eq(added_audio_block.id)
    end

    after(:all) do
      Timecop.return
    end
  end