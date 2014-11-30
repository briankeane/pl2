module PL
  class MoveSpin < UseCase   # takes new_position, old_position, station_id
    def run(attrs)

      station = PL.db.get_station(attrs[:station_id])

      if station == nil
        return failure(:station_not_found)
      end

      spin1 = PL.db.get_spin_by_current_position({ current_position: attrs[:old_position],
                                            station_id: station.id })

      if spin1 == nil
        return failure(:invalid_old_position)
      end

      new_position = PL.db.get_spin_by_current_position({ current_position: attrs[:new_position],
                                                  station_id: station.id })

      if new_position == nil
        return failure(:invalid_new_position)
      end

      station.move_spin({ station_id: station.id,
                        old_position: attrs[:old_position],
                        new_position: attrs[:new_position] })

      return success
    end
  end
end