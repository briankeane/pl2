module PL
  class GetSpinByCurrentPosition < UseCase
    def run(attrs)
      schedule = PL.db.get_schedule(attrs[:schedule_id])

      if !schedule
        return failure :schedule_not_found
      end

      spin = schedule.get_program_by_current_positions({ starting_current_position: attrs[:current_position],
                                     ending_current_position: attrs[:current_position] })[0]

      if !spin
        # see if it's already played
        spin = PL.db.get_log_entry_by_current_position({ station_id: schedule.station_id,
                                                    current_position: attrs[:current_position] })
        if !spin
          return failure(:spin_not_found)
        end
      end

      
      # 'touch' the audio-block so they are not passed to js as nil
      spin.audio_block unless spin.is_a?(CommercialBlock)

      return success :spin => spin
    end
  end
end