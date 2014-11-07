module PL
  class DeleteSpinFrequency < UseCase
    def run(attrs)
      station = PL.db.delete_spin_frequency({ station_id: attrs[:station_id], song_id: attrs[:song_id] })
      return success :station => station
    end
  end
end