module PL
  class RemoveSpin < UseCase
    def run(attrs)

      schedule = PL.db.get_schedule(attrs[:schedule_id])
      
      if schedule == nil
        return failure(:schedule_not_found)
      end

      spin_to_remove = PL.db.get_spin_by_current_position({ current_position: attrs[:current_position],
                                                   schedule_id: attrs[:schedule_id] })

      if spin_to_remove == nil
        return failure(:invalid_current_position)
      end

      # find the reinsert time (tomorrow 3am, day after tomorrow 3am if original time is between midnight and 3am)
      old_airtime = spin_to_remove.estimated_airtime

      if old_airtime.hour < 3
        day = old_airtime.day + 2
      else
        day = old_airtime.day + 1
      end
      
      replace_time = Time.new(old_airtime.year, old_airtime.month, old_airtime.day, 3) + (24*60*60*day)
      program = schedule.get_program({start_time: replace_time })
      new_position = program[0].current_position + 1     #add one to make sure it's not a commercial

      schedule.move_spin({ old_position: spin_to_remove.current_position, new_position: new_position,
                            schedule_id: schedule.id })

      return success :removed_spin => spin_to_remove
    end
  end
end
