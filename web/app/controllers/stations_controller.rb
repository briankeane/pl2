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
    @heavy = []
    @medium = []
    @light = []
  end

  def create
  end
end
