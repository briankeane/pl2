module PL
  class CreateStation < UseCase
    def run(attrs)
      user = PL.db.get_user(attrs[:user_id])
      station = PL.db.get_station_by_uid(attrs[:user_id])
      case
      when !user
        return failure(:user_not_found) 
      when station != nil
        return failure :station_already_exists, :station => station
      else
        station = PL.db.create_station(attrs)
        attrs[:station_id] = station.id
        schedule = PL.db.create_schedule({ station_id: station.id })
        station = PL.db.update_station({ id: station.id, schedule_id: schedule.id })
        return success(:station => station, :schedule => schedule)
      end
    end
  end
end
