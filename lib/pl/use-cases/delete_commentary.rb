module PL
	class DeleteCommentary < UseCase
		def run(id)
			commentary = PL.db.get_commentary(id)

			if !commentary
				return failure :commentary_not_found
			end

			commentary = PL.db.delete_commentary(id)

			return success :commentary => commentary
		end
	end
end
