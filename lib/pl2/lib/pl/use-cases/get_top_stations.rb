module PL
  class GetTopStations < UseCase
    def run(attrs={})
      stations = PL.db.get_all_stations
      
      # touch average_daily_listeners and user so they show up
      stations.each do |station| 
        station.average_daily_listeners
        station.user
      end
      stations.sort! { |station| station.average_daily_listeners }
      return success :top_stations => stations
    end
  end
end