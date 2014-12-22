module PL
  class CreatePreset < UseCase
    def run(attrs)
      station = PL.db.get_station(attrs[:station_id])
      user = PL.db.get_user(attrs[:user_id])

      case 
      when !station
        return failure :station_not_found
      when !user
        return failure :user_not_found
      end

      PL.db.create_preset({ user_id: attrs[:user_id], station_id: attrs[:station_id] })
      user_presets = PL.db.get_presets(attrs[:user_id])
      return success :presets => user_presets
    end
  end
end
