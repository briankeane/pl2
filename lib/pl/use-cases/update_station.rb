module PL
  class UpdateStation < UseCase
    def run(attrs)
      station = PL.db.get_station(attrs[:id])
      case 
      when !station
        return failure(:station_not_found)
      else
        station = PL.db.update_station(attrs)
        return success(:station => station)
      end
    end
  end
end
