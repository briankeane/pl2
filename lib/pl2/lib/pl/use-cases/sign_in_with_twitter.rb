module PL
  class SignInWithTwitter < UseCase
    def run(attrs)
      user = PL.db.get_user_by_twitter(attrs[:twitter])
      new_user = false
      if user == nil
        # create the user if there's no user
        user = PL.db.create_user({ twitter: attrs[:twitter], twitter_uid: attrs[:twitter_uid],
                                  profile_image_url: attrs[:profile_image_url] })
        new_user = true
      end

      # if the profile image has changed, update it
      if user.profile_image_url != attrs[:profile_image_url]
        user = PL.db.update_user({ id: user.id, profile_image_url: attrs[:profile_image_url] })
      end

      # use an existing session_id if possible
      session_id = PL.db.get_sid_by_uid(user.id)
      if !session_id
        session_id = PL.db.create_session(user.id)
      end

      return success :session_id => session_id, :user => user, :new_user => new_user
    end
  end
end