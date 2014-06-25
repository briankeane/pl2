module PL
	class GetRecentLogEntries < UseCase
		def run(attrs)
			station = PL.db.get_station(attrs[:station_id])

			if !station
				return failure :station_not_found
			end

			log_entries = PL.db.get_recent_log_entries(attrs)
			return success :log_entries => log_entries
		end
	end
end
