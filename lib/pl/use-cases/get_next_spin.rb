module PL
	class GetNextSpin < UseCase
		def run(station_id)
      station = PL.db.get_station(station_id)

      if !station
        return failure :station_not_found
      end

      return success :next_spin => station.next_spin
		end
	end
end
