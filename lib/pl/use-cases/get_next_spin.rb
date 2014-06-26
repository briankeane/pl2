module PL
	class GetNextSpin < UseCase
		def run(station_id)
      station = PL.db.get_station(station_id)

      if !station
        return failure :station_not_found
      end
		end
	end
end
