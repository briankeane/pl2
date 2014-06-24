module PL
  class GetUser < UseCase
    def run(id)
      user = PL.db.get_user(id)
      case 
      when !user
        return failure(:user_not_found)
      else
        return success :user => user  
      end
    end
  end
end