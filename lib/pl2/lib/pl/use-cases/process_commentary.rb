module PL
  class ProcessCommentary < UseCase
    def run(attrs)

      sh = PL::AudioFileStorageHandler.new
      station = PL.db.get_station(attrs[:station_id])
      commentary_key = sh.store_commentary({ station_id: attrs[:station_id],
                            duration: attrs[:duration],
                            audio_file: attrs[:audio_file] })
      commentary = PL.db.create_commentary({ station_id: attrs[:station_id],
                                              duration: attrs[:duration],
                                              key: commentary_key
                                              })
      spin = station.insert_spin({ add_position: attrs[:add_position],
                              station_id: attrs[:station_id],
                              audio_block_id: commentary.id })

      return success :commentary => commentary, :spin => spin
    end
  end
end