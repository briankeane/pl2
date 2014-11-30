class ListensController < ApplicationController
  def index
    @current_station = current_station
  end

  def show
    
    # grab info for view
    @listen_station = PL.db.get_station(params[:id].to_i)
    @listen_user = PL.db.get_user(@listen_station.user_id)
    @log = PL.db.get_recent_log_entries({ station_id: @listen_station.id,
                                                    count: 10 })

    
    # load audioQueue array
    gon.audioQueue = get_audio_queue(@listen_station.id)

    gon.currentStation = current_station
    gon.stationId = @listen_station.id

    # grab the 10 most recent songs
    @log = PL.db.get_recent_log_entries({ station_id: @listen_station.id, count: 30 })
    @log.shift  # get rid of now_playing
    @log.select! { |log_entry| log_entry.audio_block.is_a?(PL::Song)}
    @log = @log[0..9] unless (@log.size < 10)

  end
end
