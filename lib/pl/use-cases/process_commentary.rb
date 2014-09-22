module PL
  class ProcessCommentary < UseCase
    def run(attrs)

      sh = PL::AudioFileStorageHandler.new
      schedule = PL.db.get_schedule(attrs[:schedule_id])
      commentary_key = sh.store_commentary({ schedule_id: attrs[:schedule_id],
                            duration: attrs[:duration],
                            audio_file: attrs[:audio_file] })
      commentary = PL.db.create_commentary({ schedule_id: attrs[:schedule_id],
                                              duration: attrs[:duration],
                                              key: commentary_key
                                              })
      spin = schedule.insert_spin({ add_position: attrs[:add_position],
                              schedule_id: attrs[:schedule_id],
                              audio_block_id: commentary.id })

      return success :commentary => commentary, :spin => spin
    end
  end
end