module PL
  class GetCommercialBlockForBroadcast < UseCase
    def run(attrs)

      station = PL.db.get_station(attrs[:station_id])
      
      if !station
        return failure :station_not_found
      end

      if (attrs[:current_position] - station.now_playing.current_position) > 5
        binding.pry
        return failure :commercial_not_scheduled_yet
      end

      station.update_airtimes({ current_position: attrs[:current_position] })
      spin = PL.db.get_spin_by_current_position({ station_id: station.id, 
                                          current_position: attrs[:current_position] })
      if !spin || !spin.commercials_follow?
        return failure :no_commercial_at_current_position
      end

      commercial_block = station.get_commercial_block_for_broadcast(attrs[:current_position])

      return success :commercial_block => commercial_block 
    end
  end
end