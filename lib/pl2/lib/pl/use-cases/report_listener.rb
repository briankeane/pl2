module PL
  class ReportListener < UseCase
    def run(attrs)

      station = PL.db.get_station(attrs[:station_id])

      #validate request
      case 
      when !station
        return failure :station_not_found
      
      when !attrs[:user_id] || !PL.db.get_user(attrs[:user_id])
        return failure :user_not_found
      end

      # set previous_current_position (commercial or no?)
      if station.now_playing.is_a?(PL::CommercialBlock)
        previous_current_position = station.now_playing.current_position
      else
        previous_current_position = station.now_playing.current_position - 1
      end

      listening_session = PL.db.find_listening_session({ station_id: attrs[:station_id],
                                                      user_id: attrs[:user_id],
                                                    ending_current_position: previous_current_position
                                                    })

      # if not found, create a new one
      if !listening_session
        listening_session = PL.db.create_listening_session({ station_id: attrs[:station_id],
                                                              user_id: attrs[:user_id],
                                                              starting_current_position: station.now_playing.current_position,
                                                              ending_current_position: station.now_playing.current_position,
                                                              start_time: Time.now,
                                                              end_time: station.now_playing.estimated_end_time })
      else
        listening_session = PL.db.update_listening_session({ id: listening_session.id,
                                                              end_time: station.now_playing.estimated_end_time,
                                                              ending_current_position: station.now_playing.current_position })
      end
      return success :listening_session => listening_session
    end
  end
end