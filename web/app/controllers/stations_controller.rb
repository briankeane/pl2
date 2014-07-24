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
    binding.pry
  end
end
