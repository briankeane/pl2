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

  def get_audio_queue(schedule_id)

    now_playing = PL::GetProgramForBroadcast.run({ schedule_id: schedule_id }).program
    
    # 'touch' audio_blocks
    now_playing.each { |log| log.audio_block unless log.is_a?(PL::CommercialBlock) }

    formatted_schedule = now_playing.map do |spin|
      obj = {}
      case
      when spin.is_a?(PL::CommercialBlock)
        obj[:type] = 'CommercialBlock'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolacommercialblocks/' + spin.key
      when spin.audio_block.is_a?(PL::Song)
        obj[:type] = 'Song'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolasongs/' + spin.audio_block.key
        obj[:artist] = spin.audio_block.artist
        obj[:title] = spin.audio_block.title
      when spin.audio_block.is_a?(PL::Commentary)
        obj[:type] = 'Commentary'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolacommentaries/' + spin.audio_block.key
      end

      obj[:currentPosition] = spin.current_position
      obj[:commercialsFollow?] = spin.commercials_follow?
      obj[:airtime_in_ms] = spin.airtime_in_ms
      
      obj
    end

    formatted_schedule  
  end
  

  protect_from_forgery with: :exception
end
