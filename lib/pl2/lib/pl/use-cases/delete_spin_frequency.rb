module PL
  class DeleteSpinFrequency < UseCase
    def run(attrs)
      
      # check for station
      station = PL.db.get_station(attrs[:station_id])
      return failure :station_not_found if !station

      # check for spin_frequency
      return failure :spin_frequency_not_found if !station.spins_per_week.keys.include?(attrs[:song_id])
      
      # check for compliance with minimum levels
      return failure :minimum_spin_frequencies_met if station.spins_per_week.count <= PL::MIN_SPIN_FREQUENCY_COUNT
      # delete spin frequency
      station = PL.db.delete_spin_frequency({ station_id: attrs[:station_id], song_id: attrs[:song_id] })
      return success :station => station
    end
  end
end