module PL
  class ClearSchedule < UseCase
    def run(schedule_id)

      schedule = PL.db.get_schedule(schedule_id)

      if !schedule
        return failure :schedule_not_found
      end

      schedule.clear

      return success
    end
  end
end