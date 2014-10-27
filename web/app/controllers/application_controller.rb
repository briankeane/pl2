class ApplicationController < ActionController::Base
  helper_method :signed_in?, :current_user, :current_station, :twitter_friends

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

  def twitter_friends
    if !@twitter_friends

      # build list of all twitter friends with playola
      @twitter_friends = []

      session[:friend_ids].each do |id|
        friend = PL.db.get_user_by_twitter_uid(id.to_s)
        @twitter_friends << friend unless !friend
      end
    end

    @twitter_friends
  end

  
  protect_from_forgery with: :exception
end
