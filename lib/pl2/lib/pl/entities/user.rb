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
  end
end
