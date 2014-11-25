module PL
  class ClearSchedule < UseCase
    def run(schedule)id

      schedule = PL.db.get_schedule(schedule_id)

      if !schedule
        return failure :schedule_not_found
      end

      schedule.clear

      commercial_block = station.get_commercial_block_for_broadcast(attrs[:current_position])

      return success :commercial_block => commercial_block 
    end
  end
end