module PL
  class GetProgram < UseCase
    def run(attrs)
      station = PL.db.get_station(attrs[:station_id])

      if !station
        return failure :station_not_found
      end

      program = station.get_program({ station_id: station.id,
                                      start_time: attrs[:start_time],
                                     end_time: attrs[:end_time] })
      if program.size == 0
        return failure(:no_playlist_for_requested_time)
      else
        return success :program => program
      end
      
    end
  end
end