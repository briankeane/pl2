module PL
	class CreateStation < UseCase
		def run(attrs)
			user = PL.db.get_user(attrs[:user_id])
			station = PL.db.get_station_by_user_id(attrs[:user_id])
			case
			when !user
				return failure(:user_not_found) 
			when station != nil
				return failure(:station_already_exists, :station => station)
			when attrs[:heavy].size < PL::MIN_HEAVY_COUNT
				return failure(:not_enough_heavy_rotation_songs, :minimum_required => PL::MIN_HEAVY_COUNT)
			when attrs[:medium].size < PL::MIN_MEDIUM_COUNT
				return failure(:not_enough_medium_rotation_songs, :minimum_required => PL::MIN_MEDIUM_COUNT)
			when attrs[:light].size < PL::MIN_LIGHT_COUNT
				return failure(:not_enough_light_rotation_songs, :minimum_required => PL::MIN_LIGHT_COUNT)
			else
				station = PL.db.create_station(attrs)
				return success(:station => station)
			end
		end
	end
end
