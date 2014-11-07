module PL
  class CreateUser < UseCase
    def run(attrs)
      user = PL.db.get_user_by_twitter(attrs[:twitter])

      case 
      when user != nil
        return failure(:user_already_exists)
      when !attrs[:twitter]
        return failure(:no_twitter_provided)
      when !attrs[:twitter_uid]
        return failure(:no_twitter_uid_provided)
      when !attrs[:email]
        return failure(:no_email_provided)
      when !attrs[:birth_year]
        return failure(:no_birth_year_provided)
      when !attrs[:gender]
        return failure(:no_gender_provided)
      else
        user = PL.db.create_user(attrs)
        return success :user => user
      end
    end
  end
end
