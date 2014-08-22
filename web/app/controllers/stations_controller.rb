class StationsController < ApplicationController
  def dj_booth

    if !current_station
      return redirect_to station_new_path
    end

    result = PL::GetProgram.run({ station_id: current_station.id })
    if result.success?
      @program = result.program
    end

    @current_spin = current_station.now_playing
  end

  def playlist_editor
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
        @spins_per_week[song] = PL::HEAVY_ROTATION
      end

      result.song_suggestions[13..40].each do |song|
        @spins_per_week[song] = PL::MEDIUM_ROTATION 
      end

      result.song_suggestions[41..53].each do |song|
        @spins_per_week[song] = PL::MEDIUM_ROTATION
      end

      result = PL::CreateStation.run({ user_id: current_user.id,
                                       spins_per_week: @spins_per_week })

      all_songs_result = PL::GetAllSongs.run()
      @all_songs = all_songs_result.all_songs

    end
  end
end
