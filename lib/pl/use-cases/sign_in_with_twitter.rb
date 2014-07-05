module PL
  class SignInWithTwitter < UseCase
    def run(attrs)
      user = PL.db.get_user_by_twitter(attrs[:twitter])
      new_user = false
      if user == nil
        # create the user if there's no user
        user = PL.db.create_user({ twitter: attrs[:twitter], twitter_uid: attrs[:twitter_uid] })
        new_user = true
      end

      session_id = PL.db.create_session(user.id)
      return success :session_id => session_id, :user => user, :new_user => new_user
    end
  end
end