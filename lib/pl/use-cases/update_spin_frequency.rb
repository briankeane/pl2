module PL
  class UpdateSpinFrequency < UseCase
    def run(attrs)
      song = PL.db.get_song(attrs[:song_id])
      station = PL.db.get_station(attrs[:station_id])

      case
      when !song
        return failure :song_not_found
      when !station
        return failure :station_not_found
      else
        updated_station = PL.db.update_spin_frequency(attrs)
        return success :updated_station => updated_station
      end
    end
  end
end