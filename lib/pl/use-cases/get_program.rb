module PL
  class GetProgram < UseCase
    def run(attrs)
      schedule = PL.db.get_schedule(attrs[:schedule_id])

      if !schedule
        return failure :schedule_not_found
      end

      program = schedule.get_program({ schedule_id: attrs[:schedule_id],
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