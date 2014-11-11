class ApplicationController < ActionController::Base

  helper_method :signed_in?, :current_user, :current_station, :current_schedule, :twitter_friends_stations

  def current_user
    @current_user ||= PL.db.get_user(PL.db.get_uid_by_sid(session[:pl_session_id]))
  end

  def current_station
    @current_station ||= PL.db.get_station_by_uid(current_user.id)
  end

  def signed_in?
    current_user != nil
  end

  def current_schedule
    PL.db.get_schedule(current_station.schedule_id)
    #@current_schedule ||= PL.db.get_schedule(current_station.schedule_id)
  end

  def twitter_friends_stations
    PL::GetFollowedStations.run(current_user.id).followed_stations_list
  end

  protect_from_forgery with: :exception
end
