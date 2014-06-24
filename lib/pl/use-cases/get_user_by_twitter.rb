module PL
  class GetUserByTwitter < UseCase
    def run(twitter)
      user = PL.db.get_user_by_twitter(twitter)
      case 
      when !user
        return failure :twitter_not_found
      else
        return success :user => user
      end
    end
  end
end