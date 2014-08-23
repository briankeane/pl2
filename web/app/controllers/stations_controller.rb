class StationsController < ApplicationController
  
  def dj_booth
    if !current_station || !current_station.schedule  
      return redirect_to station_new_path
    end

    result = PL::GetProgram.run({ station_id: current_station.id })
    
    if result.success?
      @program = result.program
    end

    @current_spin = current_station.now_playing
  end

  def song_manager
    if !current_station || !current_station.schedule
      return redirect_to station_new_path
    end

    @spins_per_week = {}
    current_station.spins_per_week.each { |k,v| @spins_per_week[PL.db.get_song(k)] = v }

    all_songs_result = PL::GetAllSongs.run()
    @all_songs = all_songs_result.all_songs
    binding.pry
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

      redirect_to station_song_manager_path
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
