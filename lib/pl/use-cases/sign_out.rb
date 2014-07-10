module PL
  class SignOut < UseCase
    def run(session_id)
      PL.db.delete_session(session_id)
      return success
    end
  end
end