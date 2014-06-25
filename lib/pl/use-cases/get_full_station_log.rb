module PL
	class GetFullStationLog < UseCase
		def run(station_id)
			station = PL.db.get_station(station_id)

			if !station
				return failure :station_not_found
			end

			log = PL.db.get_full_station_log(station_id)

			return success :log => log
		end
	end
end
