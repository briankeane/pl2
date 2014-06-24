module PL
  class DeleteUser < UseCase
    def run(id)
      user = PL.db.delete_user(id)
      case 
      when !user
        return failure(:user_not_found)
      else
        return success :user => user  
      end
    end
  end
end