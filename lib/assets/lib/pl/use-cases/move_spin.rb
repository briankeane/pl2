module PL
  class MoveSpin < UseCase   # takes new_position, old_position, schedule_id
    def run(attrs)

      schedule = PL.db.get_schedule(attrs[:schedule_id])

      if schedule == nil
        return failure(:schedule_not_found)
      end

      spin1 = PL.db.get_spin_by_current_position({ current_position: attrs[:old_position],
                                            schedule_id: schedule.id })

      if spin1 == nil
        return failure(:invalid_old_position)
      end

      new_position = PL.db.get_spin_by_current_position({ current_position: attrs[:new_position],
                                                  schedule_id: schedule.id })

      if new_position == nil
        return failure(:invalid_new_position)
      end

      schedule.move_spin({ schedule_id: schedule.id,
                        old_position: attrs[:old_position],
                        new_position: attrs[:new_position] })

      return success
    end
  end
end