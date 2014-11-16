#############################################################
#  eventually this class will stuff the right commercials   #
#  into the right commercial blocks at the right time.  For #
#  now it just returns a commercial block                   #
#############################################################

module PL
  class CommercialBlockFactory
    def construct_block(attrs)
      
      # if no commercial has aired yet or it's cycled through all commercial_blocks
      if !attrs[:station].last_commercial_block_aired || attrs[:station].last_commercial_block_aired >= PL::FINAL_COMMERCIAL_BLOCK
        this_commercial_block = 1
      else 
        this_commercial_block = (attrs[:station].last_commercial_block_aired + 1)
      end
      
      # construct key
      commercial_block_key = this_commercial_block.to_s.rjust(4, padstr='0') + '_commercial_block.mp3'  
      
      # grab the airtime
      leading_spin = PL.db.get_spin_by_current_position({ schedule_id: attrs[:station].schedule_id, current_position: attrs[:current_position]})

      if !leading_spin
        leading_spin = PL.db.get_log_entry_by_current_position({ station_id: attrs[:station].id, current_position: attrs[:current_position] })
      end

      airtime = leading_spin.estimated_end_time
      
      commercial_block = PL.db.create_commercial_block({ duration: attrs[:station].secs_of_commercial_per_hour*1000,
                                                          station_id: attrs[:station].id,
                                                          key: commercial_block_key,
                                                          current_position: attrs[:current_position],
                                                          airtime: airtime })

      
      # reset lastCommecialBlockAired and store it in the db
      attrs[:station].last_commercial_block_aired = this_commercial_block
      PL.db.update_station({ id: attrs[:station].id,
                              last_commercial_block_aired: this_commercial_block })
      
      commercial_block
    end
  end
end