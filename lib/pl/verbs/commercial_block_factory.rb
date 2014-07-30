#############################################################
#  eventually this class will stuff the right commercials   #
#  into the right commercial blocks at the right time.  For #
#  now it just returns a commercial block                   #
#############################################################

module PL
  class CommercialBlockFactory
    def construct_block(station)
      commercial_block = PL.db.create_commercial_block({ duration: station.secs_of_commercial_per_hour*1000,
                                                          station_id: station.id })
      commercial_block
    end
  end
end