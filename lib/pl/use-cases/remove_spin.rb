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

      PL.db.remove_spin({ current_position: attrs[:current_position],
                          schedule_id: attrs[:schedule_id] })
    end
  end
end
