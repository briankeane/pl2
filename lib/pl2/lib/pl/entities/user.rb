module PL
  class User < Entity
    attr_accessor :id, :twitter, :twitter_uid, :email, :zipcode, :profile_image_url
    attr_accessor :birth_year, :gender, :created_at, :updated_at, :timezone

    def intialize(attrs)
      super(attrs)
    end

    def station
      PL.db.get_station_by_uid(@id)
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      hash
    end
  end
end
