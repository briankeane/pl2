module PL
  # takes in an array of twitter ids, finds out which ones have stations, stores those in the db,
  #   and returns an array of those stations
  class GetFollowedStations < UseCase
    def run(user_id)
      # return if user_id is invalid
      if !PL.db.get_user(user_id)
        return failure :user_not_found
      end

      list = PL.db.get_followed_stations_list(user_id)

      followed_stations = list.map { |station_id| PL.db.get_station(station_id) }

      return success :followed_stations_list => followed_stations
    end
  end
end
