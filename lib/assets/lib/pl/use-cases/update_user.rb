module PL
  class UpdateUser < UseCase
    def run(attrs)
      user = PL.db.get_user(attrs[:id])

      if !user
        return failure(:user_not_found)
      else
        user = PL.db.update_user(attrs)
        return success :user => user
      end
    end
  end
end