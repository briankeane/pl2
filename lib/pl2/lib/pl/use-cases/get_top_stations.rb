module PL
  class GetTopStations < UseCase
    def run(attrs={})
      stations = PL.db.get_all_stations
      stations.sort! { |station| station.average_daily_listeners }
      return success :top_stations => stations[0..19]
    end
  end
end