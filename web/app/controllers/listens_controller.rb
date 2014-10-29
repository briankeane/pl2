class ListensController < ApplicationController
  def index
    @current_schedule = current_schedule
  end

  def show
    @listen_station = PL.db.get_station(params[:id].to_i)
    @listen_user = PL.db.get_user(@listen_station.user_id)
  end
end
