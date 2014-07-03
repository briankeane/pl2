module PL
  class CreateStation < UseCase
    def run(attrs)
      user = PL.db.get_user(attrs[:user_id])
      station = PL.db.get_station_by_user_id(attrs[:user_id])
      case
      when !user
        return failure(:user_not_found) 
      when station != nil
        return failure(:station_already_exists, :station => station)
      else
        station = PL.db.create_station(attrs)
        return success(:station => station)
      end
    end
  end
end
