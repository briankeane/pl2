module PL
	class GetPlaylist < UseCase
		def run(attrs)
			station = PL.db.get_station(attrs[:station_id])

			if !station
				return failure :station_not_found
			end

			playlist = get_playlist({ station_id: station.id,
																start_time: start_time,
																end_time: end_time })
			if playlist.size == 0
				return failure(:no_playlist_for_requested_time)
			end
			
		end
	end
end