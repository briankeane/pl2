module PL
  class DeletePreset < UseCase
    def run(attrs)

      old_presets = PL.db.get_presets(attrs[:user_id])

      if !old_presets.include?(attrs[:station_id])
        return failure :preset_not_found
      end

      PL.db.delete_preset({ station_id: attrs[:station_id], user_id: attrs[:user_id] })
      
      user_presets = PL.db.get_presets(attrs[:user_id])
      return success :presets => user_presets
    end
  end
end
