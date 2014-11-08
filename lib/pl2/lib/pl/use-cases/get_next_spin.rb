module PL
	class GetNextSpin < UseCase
		def run(schedule_id)
      station = PL.db.get_station(schedule_id)

      if !station
        return failure :schedule_not_found
      end

      return success :next_spin => station.next_spin
		end
	end
end
