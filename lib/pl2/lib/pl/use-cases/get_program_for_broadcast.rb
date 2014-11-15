module PL
  class GetProgramForBroadcast < UseCase
    def run(attrs)
      schedule = PL.db.get_schedule(attrs[:schedule_id])

      if !schedule
        return failure :schedule_not_found
      end

      station = PL.db.get_station(schedule.station_id)

      if !station
        return failure :station_not_found
      end

      program = schedule.get_program({ schedule_id: attrs[:schedule_id],
                                      start_time: attrs[:start_time],
                                     end_time: attrs[:end_time] })
      if program.size == 0
        return failure(:no_playlist_for_requested_time)
      else

        # just use the next 3 spins unless last one is a commercial
        if program[2].is_a?(PL::CommercialBlock)
          program = program.take(4)
        else
          program = program.take(3)
        end

        # 'touch' the audio-blocks so they are not passed to js as nil
        # also grab the commercial_blocks
        program.map! do |spin|
          if spin.is_a?(PL::CommercialBlock)
            station.get_commercial_block_for_broadcast(spin.current_position)
          else
            spin.audio_block
          end
        end

        return success :program => program
      end
    end
  end
end