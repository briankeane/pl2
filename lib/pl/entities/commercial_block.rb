module PL
  class CommercialBlock < Entity

    attr_accessor :id, :duration, :estimated_airtime, :commercials, :station_id, :cb_position, :audio_file

    def initialize(attrs)
      attrs[:duration] ||= 180000
      attrs[:commercials] ||= []
      super(attrs)

      #if commercial ids were passed, store them
      if attrs[:commercial_ids]
        attrs[:commercial_ids].each do |id|
          @commercials << PL.db.get_commercial(id)
        end
      end
    end
  end
end