module PL
  class UpdateLogEntry < UseCase
    def run(attrs)
      entry = PL.db.get_log_entry(attrs[:id])

      if !entry
        return failure :log_entry_not_found
      end

      entry = PL.db.update_log_entry(attrs)

      return success :entry => entry
    end
  end
end