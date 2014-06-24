module PL
  class GetCommentary < UseCase
    def run(id)
      commentary = PL.db.get_commentary(id)

      if !commentary
        return failure :commentary_not_found
      else
        return success :commentary => commentary
      end
    end
  end
end