module PL
  # takes in an array of twitter ids, finds out which ones have stations, stores those in the db,
  #   and returns an array of those stations
  class StoreTwitterFriendStations < UseCase
    def run(attrs)
      user = PL.db.get_user(attrs[:user_id])
      
      # return if user_id is invalid
      if !user
        return failure :user_not_found
      end

      followed_stations = []

      attrs[:friend_twitter_uids].each do |id|
        friend = PL.db.get_user_by_twitter_uid(id)
        followed_stations << friend.station unless (!friend || !friend.station)
      end

      if followed_stations.size == 0
        return success :followed_stations_list => []
      else
        PL.db.store_twitter_friends({ follower_uid: user.id,
                                      followed_station_ids: followed_stations.map { |station| station.id } })
        return success :followed_stations_list => followed_stations
      end
    end
  end
end
