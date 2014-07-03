module PL
  class RecordSpinFrequency < UseCase
    def run(attrs)
      station = PL.db.get_station(attrs[:station_id])
      song = PL.db.get_song(attrs[:song_id])
      case 
      when !station
        return failure :station_not_found
      when !song
        return failure :song_not_found
      else
        updated_station = PL.db.record_spin_frequency(attrs)
        return success :updated_station => updated_station
      end
    end
  end
end
