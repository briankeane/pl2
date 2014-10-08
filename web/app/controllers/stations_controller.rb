class StationsController < ApplicationController
  
  def dj_booth

    return redirect_to station_new_path unless current_station

    result = PL::GetProgram.run({ schedule_id: current_schedule.id })
    @program = result.program unless !result.success?
    
    now_playing = PL::GetProgram.run({ schedule_id: current_schedule.id }).program
    
    now_playing.unshift(current_schedule.now_playing)

    gon.audioQueue = now_playing[0..2].map do |spin|
      obj = {}
      case
      when spin.is_a?(PL::CommercialBlock)
        obj[:type] = 'CommercialBlock'
        obj[:key] = 'STUBFORCBKEY'
      when spin.audio_block.is_a?(PL::Song)
        obj[:type] = 'Song'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolasongs/' + spin.audio_block.key
      when spin.audio_block.is_a?(PL::Commentary)
        obj[:type] = 'Commentary'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolasongs/' + spin.audio_block.key
      end

      if spin.is_a?(PL::LogEntry)
        obj[:airtime_in_ms] = spin.airtime.to_f * 1000
      else
        obj[:airtime_in_ms] = spin.estimated_airtime.to_f * 1000
      end
      obj
    end
    
    # convert to local time
    @program.each do |spin|
      spin.estimated_airtime = spin.estimated_airtime.in_time_zone(current_station.timezone)
    end



    # set first_current_position if commercial block is first
    if @program.last.is_a?(PL::CommercialBlock)
      @first_current_position = @program[1].current_position
    else
      @first_current_position = @program[0].current_position
    end

    @now_playing = current_station.now_playing
    @all_songs = PL.db.get_all_songs
  end

  def song_manager
    if !current_station || !current_station.schedule
      return redirect_to station_new_path
    end

    @spins_per_week = {}
    current_station.spins_per_week.each { |k,v| @spins_per_week[PL.db.get_song(k)] = v }

    all_songs_result = PL::GetAllSongs.run()
    @all_songs = all_songs_result.all_songs
  end

  def new
    @songs = PL.db.get_all_songs

    # tell the browser whether or not to collect the user info
    if current_user.gender && current_user.birth_year && current_user.zipcode
      @user_info_complete = true
    else
      @user_info_complete = false
    end

    if !current_station
      @station_info_complete = false
    end
  end

  def create
    artists = params[:artist].values.delete_if { |artist| artist.empty? }

    result = PL::GetSongSuggestions.run(artists)

    if params["createType"] == "manual"
    else
      spins_per_week = {}

      # if the returned sample is too small, add random songs to make it
      # big enough to work with
      if result.song_suggestions.size < 54
        all_songs_result = PL::GetAllSongs.run()
        all_songs = PL.db.get_all_songs
        result.song_suggestions.each { |song| all_songs_result.all_songs.delete(song.id) }
        
        while result.song_suggestions.size < 54
          random_song = all_songs_result.all_songs.sample
          result.song_suggestions.push(random_song)
          all_songs_result.all_songs.delete(random_song.id)
        end
      end
      
      @spins_per_week = {}

      result.song_suggestions[0..12].each do |song|
        @spins_per_week[song.id] = PL::HEAVY_ROTATION
      end

      result.song_suggestions[13..40].each do |song|
        @spins_per_week[song.id] = PL::MEDIUM_ROTATION 
      end

      result.song_suggestions[41..53].each do |song|
        @spins_per_week[song.id] = PL::MEDIUM_ROTATION
      end

      result = PL::CreateStation.run({ user_id: current_user.id,
                                       spins_per_week: @spins_per_week })

      current_schedule.generate_playlist(Time.now + (24*60*60))
      @current_schedule = PL.db.get_schedule(current_schedule.id)

      redirect_to listens_index_path
    end
  end

  def create_spin_frequency
    case params[:spins_per_week]
    when 'Heavy'
      spins_per_week = PL::HEAVY_ROTATION
    when 'Medium'
      spins_per_week = PL::MEDIUM_ROTATION
    when 'Light'
      spins_per_week = PL::LIGHT_ROTATION
    end

    result = PL::CreateSpinFrequency.run({ spins_per_week: spins_per_week,
                                              station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end

  def update_spin_frequency
    case params[:spins_per_week]
    when 'Heavy'
      spins_per_week = PL::HEAVY_ROTATION
    when 'Medium'
      spins_per_week = PL::MEDIUM_ROTATION
    when 'Light'
      spins_per_week = PL::LIGHT_ROTATION
    end

    result = PL::UpdateSpinFrequency.run({ spins_per_week: spins_per_week,
                                              station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end

  def delete_spin_frequency
    result = PL::DeleteSpinFrequency.run({ station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end


end
