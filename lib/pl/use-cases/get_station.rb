module PL
  class GetStation < UseCase
    def run(id)
      station = PL.db.get_station(id)
      case 
      when !station
        return failure(:station_not_found)
      else
        return success(:station => station)
      end
    end
  end
end