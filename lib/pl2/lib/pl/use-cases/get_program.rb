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
        # 'touch' the audio-blocks so they are not passed to js as nil
        program.map { |spin| spin.audio_block unless spin.is_a?(CommercialBlock) }

        return success :program => program
      end
    end
  end
end