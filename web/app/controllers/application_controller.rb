class ApplicationController < ActionController::Base
  helper_method :signed_in?, :current_user, :current_station

  def current_user
    @current_user ||= PL.db.get_user(PL.db.get_uid_by_sid(session[:pl_session_id]))
  end

  def current_station
    @current_station ||= PL.db.get_station_by_uid(current_user.id)
  end

  def signed_in?
    if current_user
      return true
    else
      return false
    end
  end

  protect_from_forgery with: :exception
end
