module PL
  class InsertSpin < UseCase
    def run(attrs)
      station = PL.db.get_station(attrs[:station_id])
      
      return failure :station_not_found if !station
      
      spin = station.insert_spin(attrs)
      return success :added_spin => spin
    end
  end
end