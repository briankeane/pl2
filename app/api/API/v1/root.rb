module API
  module V1
    class Root < Grape::API
      version "v1"
      format :json
      #error_format :json

      # load the rest of the API
      mount API::V1::Songs
    end
  end
end