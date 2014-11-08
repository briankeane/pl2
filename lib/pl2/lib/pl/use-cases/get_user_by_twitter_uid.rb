module PL
  class GetUserByTwitterUID < UseCase
    def run(twitter_uid)
      user = PL.db.get_user_by_twitter_uid(twitter_uid)
      case 
      when !user
        return failure :twitter_not_found
      else
        return success :user => user
      end
    end
  end
end