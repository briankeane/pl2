module API
  module V1
    class Root < Grape::API
      version "v1"
      format :json
      #error_format :json

      # load the rest of the API
      mount V1::Auth
      mount V1::Users
      mount V1::Songs
    end
  end
end