module PL
  class RemoveSpin < UseCase
    def run(attrs)

      station = PL.db.get_station(attrs[:station_id])
      
      if station == nil
        return failure(:station_not_found)
      end

      spin_to_remove = PL.db.get_spin_by_current_position({ current_position: attrs[:current_position],
                                                   station_id: attrs[:station_id] })

      if spin_to_remove == nil
        return failure(:invalid_current_position)
      end

      # find the reinsert time (tomorrow 3am, day after tomorrow 3am if original time is between midnight and 3am)
      old_airtime = spin_to_remove.airtime

      if old_airtime.hour < 3
        extra_days = 2
      else
        extra_days = 1
      end
      
      replace_time = Time.new(old_airtime.year, old_airtime.month, old_airtime.day, 3) + (24*60*60*extra_days)
      program = station.get_program({start_time: replace_time })
      new_position = program[0].current_position + 1     #add one to make sure it's not a commercial

      station.move_spin({ old_position: spin_to_remove.current_position, new_position: new_position,
                            station_id: station.id })

      return success :removed_spin => spin_to_remove
    end
  end
end
