#############################################################
#  eventually this class will stuff the right commercials   #
#  into the right commercial blocks at the right time.  For #
#  now it just returns a commercial block                   #
#############################################################

module PL
  class CommercialBlockFactory
    def construct_block(station)
      this_commercial_block = (station.last_commercial_block_aired + 1) unless !station.last_commercial_block_aired
      
      # if it's past the last commercial
      if this_commercial_block > PL::FINAL_COMMERCIAL_BLOCK
        this_commercial_block = 1
      end
      
      # construct key
      commercial_block_key = this_commercial_block.to_s.rjust(4, padstr='0') + '_commercial_block.mp3'  
      
      commercial_block = PL.db.create_commercial_block({ duration: station.secs_of_commercial_per_hour*1000,
                                                          station_id: station.id,
                                                          key: commercial_block_key })

      
      # reset lastCommecialBlockAired and store it in the db
      station.last_commercial_block_aired = this_commercial_block
      PL.db.update_station({ id: station.id,
                              last_commercial_block_aired: this_commercial_block })
      
      commercial_block
    end
  end
end