module PL
  class InsertSpin < UseCase
    def run(attrs)
      schedule = PL.db.get_schedule(attrs[:schedule_id])
      spin = schedule.insert_spin(attrs)
      return success :added_spin => spin
    end
  end
end