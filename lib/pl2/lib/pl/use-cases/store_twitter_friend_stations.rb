module PL
  # takes in an array of twitter ids, finds out which ones have stations, stores those in the db,
  #   and returns an array of those stations
  class StoreTwitterFriendStations < UseCase
    def run(attrs)
      # return if user_id is invalid
      if !PL.db.get_user(attrs[:user_id])
        return failure :user_not_found
      end

      followed_stations = []

      attrs[:friend_ids].each do |id|
        friend = PL.db.get_user_by_twitter_uid(id)
        followed_stations << friend.station unless (!friend || !friend.station)
      end

      return success :followed_stations_list => followed_stations
    end
  end
end
